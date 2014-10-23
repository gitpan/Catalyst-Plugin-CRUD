package Catalyst::Helper::Model::CRUD;

use strict;
use Jcode;
use XML::Simple;

our $VERSION = '0.03';

=head1 NAME

Catalyst::Helper::Model::CRUD - generate sqls, controllers and templates from DBDesigner 4 file

=head1 SYNOPSIS

    ./myapp_create.pl model CRUD CRUD [DBDesigner 4 File] [some modules]

=head1 DESCRIPTION

Helper for Catalyst::Plugin::CRUD.

This helper generates sqls, default controllers and default templates.

=head1 METHODS

=cut

# relation list
my @relations;

# table list
my @tables;

=head2 encode($str)

translate DBDesigner 4's comment to EUC-JP

=cut

sub encode {
    my ( $this, $str ) = @_;
    my @array = split( //, $str );
    my @list;
    for ( my $i = 0; $i < scalar(@array); $i++ ) {

        # translate "\\n" to "��"
        if ( $array[$i] eq '\\' && $array[ $i + 1 ] eq 'n' ) {
            push @list, 129;
            push @list, 66;
            $i++;

            # translate "\\\\" to "0x5C"
        }
        elsif ( $array[$i] eq '\\' && $array[ $i + 1 ] eq '\\' ) {
            push @list, 92;
            $i++;

            # "\\144" etc
        }
        elsif ( $array[$i] eq '\\' ) {
            push @list, $array[ $i + 1 ] . $array[ $i + 2 ] . $array[ $i + 3 ];
            $i += 3;

            # "[" etc
        }
        elsif ( 13 < ord( $array[$i] ) && ord( $array[$i] ) < 128 ) {
            push @list, ord( $array[$i] );
        }
    }

    # translate Shift-JIS to EUC-JP
    my $result = pack( "C*", @list );
    return jcode( $result, 'sjis' )->euc;
}

=head2 get_class_name($str)

translate hoge_fuga_master to HogeFugaMaster

=cut

sub get_class_name {
    my ( $this, $str ) = @_;
    my @array = split( //, $str );
    for ( my $i = 0; $i < scalar(@array); $i++ ) {
        if ( $i == 0 ) {
            $array[$i] = uc $array[$i];
        }
        elsif ( $array[$i] eq '_' ) {
            $array[ $i + 1 ] = uc $array[ $i + 1 ];
        }
    }
    my $result = join( '', @array );
    $result =~ s/_//g;
    return $result;
}

=head2 get_relation($relation_id)

get appinted ID's relation

=cut

sub get_relation {
    my ( $this, $relation_id ) = @_;
    foreach my $relation (@relations) {
        if ( $relation_id eq $relation->{'ID'} ) {
            return $relation;
        }
    }
}

=head2 get_table($table_id)

get appointed ID's table

=cut

sub get_table {
    my ( $this, $table_id ) = @_;
    foreach my $table (@tables) {
        if ( $table_id eq $table->{'ID'} ) {
            return $table;
        }
    }
}

=head2 get_schema_index($array, $name)

get appointed name's schema number

=cut

sub get_schema_index {
    my ( $this, $array, $name ) = @_;
    for ( my $i = 0; $i < scalar( @{$array} ); $i++ ) {
        if ( $name eq $array->[$i]->{'name'} ) {
            return $i;
        }
    }
    return -1;
}

=head2 get_primary(@sqls)

get primary key name

=cut

sub get_primary {
    my ( $this, @sqls ) = @_;
    for my $sql (@sqls) {
        if ( $sql->{type} eq 'serial' ) {
            return $sql->{name};
        }
    }
    return 'id';
}

=head2 get_columns(@sqls)

get columns string

=cut

sub get_columns {
    my ( $this, @sqls ) = @_;
    shift @sqls;
    my @names;
    for my $sql (@sqls) {
        push @names, $sql->{name};
    }
    return join( " ", @names );
}

=head2 mk_compclass($helper, $file, @limited_file)

analyse DBDesigner 4 file and generate sqls, controllers and templates

=cut

sub mk_compclass {
    my ( $this, $helper, $file, @limited_file ) = @_;
    print "==========================================================\n";

    # �ե�����̾��ɬ��
    unless ($file) {
        die "usage: ./myapp_create.pl model CRUD CRUD [DBDesigner 4 File] [some modules]\n";
        return 1;
    }

    # XML�ե��������
    my $parser = new XML::Simple();
    my $tree   = $parser->XMLin($file);

    # SQL������ȥ��顦�ƥ�ץ졼���ѤΥǥ��쥯�ȥ����
    my $schema_dir     = sprintf( "%s/sql/schema", $helper->{'base'} );
    my $controller_dir = sprintf( "%s/lib/%s/Controller",   $helper->{'base'}, $helper->{'app'} );
    my $template_dir   = sprintf( "%s/root/template",  $helper->{'base'} );
    $helper->mk_dir($schema_dir);
    $helper->mk_dir($controller_dir);
    $helper->mk_dir($template_dir);

    # ��졼�����ȥơ��֥�������������
    @relations = @{ $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} }
        if ref $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} eq 'ARRAY';
    @tables = @{ $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} }
        if ref $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} eq 'ARRAY';

    # ���ꤷ���⥸�塼��Τ�
    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    foreach my $table (@tables) {
        my $class_name = $this->get_class_name( $table->{'Tablename'} );

        # ���ꤷ���⥸�塼��Τ�
        if ( scalar @limited_file ) {
            next unless ( $limit{$class_name} );
        }

        # �ƥơ��֥�����������
        my @columns = @{ $table->{'COLUMNS'}->{'COLUMN'} } if ref $table->{'COLUMNS'}->{'COLUMN'} eq 'ARRAY';

        # �ƥơ��֥�Υ���ǥå���������
        my %indices;
        if ( ref( $table->{'INDICES'}->{'INDEX'} ) eq 'HASH' ) {

            # ���ǰ�ĤΤȤ��ϥϥå���ˤʤäƤ��ޤ��ΤǤ����к�
            my $key = $table->{'INDICES'}->{'INDEX'}->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
            my $val = $table->{'INDICES'}->{'INDEX'}->{'FKRefDef_Obj_id'};

            # �祭����̵�뤹��
            unless ( $val eq '-1' ) {
                $indices{$key} = $val;
            }
        }
        elsif ( ref( $table->{'INDICES'}->{'INDEX'} ) eq 'ARRAY' ) {
            foreach my $index ( @{ $table->{'INDICES'}->{'INDEX'} } ) {
                my $key = $index->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
                my $val = $index->{'FKRefDef_Obj_id'};

                # �祭����̵�뤹��
                unless ( $val eq '-1' ) {
                    $indices{$key} = $val;
                }
            }
        }

        my @serials;    # �������󥹰���
        my @sqls;       # SQL����
        my @schemas;    # �������ް���
        foreach my $column (@columns) {
            my $sql;
            my @schema;

            # �����̾
            push @schema, ( "        " . $column->{'ColName'} );

            # ��
            if ( $column->{'AutoInc'} eq "1" ) {

                # AutoInc="1" ���ä���֥ơ��֥�̾_�����̾_seq�פȤ���
                # �ơ��֥�� Postgresql ����ư��������ΤǤ����б�
                $sql->{'type'} = "serial";
                push @schema, "SERIAL";
                push @serials,
                    sprintf( "GRANT ALL ON %s_%s_seq TO PUBLIC;\n", $table->{'Tablename'}, $column->{'ColName'} );
            }
            elsif ( $column->{'idDatatype'} eq '5' ) {
                $sql->{'type'} = "int";
                push @schema, "INTEGER";
            }
            elsif ( $column->{'idDatatype'} eq '14' ) {
                $sql->{'type'} = "date";
                push @schema, "DATE";
            }
            elsif ( $column->{'idDatatype'} eq '16' ) {
                $sql->{'type'} = "timestamp with time zone";
                push @schema, "TIMESTAMP with time zone";
            }
            elsif ( $column->{'idDatatype'} eq '20' ) {
                $sql->{'type'} = "varchar(255)";
                push @schema, "VARCHAR(255)";
            }
            elsif ( $column->{'idDatatype'} eq '22' ) {
                $sql->{'type'} = "bool";
                push @schema, "BOOL";
            }
            elsif ( $column->{'idDatatype'} eq '28' ) {
                $sql->{'type'} = "text";
                push @schema, "TEXT";
            }
            else {
                $sql->{'type'} = "text";
                push @schema, "TEXT";
            }

            # �祭�����ɤ���
            if ( $column->{'PrimaryKey'} eq '1' ) {
                $sql->{'primarykey'} = 1;
                push @schema, "PRIMARY KEY";
            }
            elsif ( 'id' eq lc( $column->{'ColName'} ) ) {

                # id �ϼ�ưŪ�˼祭���ˤ���
                $sql->{'primarykey'} = 1;
                push @schema, "PRIMARY KEY";
            }

            # �ǥե������
            if ( length( $column->{'DefaultValue'} ) > 0 ) {
                $sql->{'default'} = $column->{'DefaultValue'};
                push @schema, sprintf( "DEFAULT '%s'", $column->{'DefaultValue'} );
            }
            elsif ( $column->{'idDatatype'} eq '14' ) {

                # ���դϼ�ưŪ�����ꤹ��
                $sql->{'default'} = "('now'::text)::timestamp";
                push @schema, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( $column->{'idDatatype'} eq '16' ) {

                # �����ϼ�ưŪ�����ꤹ��
                $sql->{'default'} = "('now'::text)::timestamp";
                push @schema, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable �ϼ�ưŪ�� 0 �ˤ���
                $sql->{'default'} = "0";
                push @schema, "DEFAULT '0'";
            }

            # NOT NULL ����
            if ( $column->{'NotNull'} eq '1' ) {
                $sql->{'notnull'} = 1;
                push @schema, "NOT NULL";
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable �ϼ�ưŪ�� NOT NULL �ˤ���
                $sql->{'notnull'} = 1;
                push @schema, "NOT NULL";
            }

            # ��������
            if ( $indices{ $column->{'ID'} } ) {
                my $relation   = $this->get_relation( $indices{ $column->{'ID'} } );
                my $src_table  = $this->get_table( $relation->{'SrcTable'} );
                my $class_name = sprintf( "%s::Model::ShanonDBI::%s",
                    $helper->{'app'}, $this->get_class_name( $src_table->{'Tablename'} ) );
                $sql->{'references'} = {
                    class    => $class_name,
                    name     => 'id',
                    onupdate => 'cascade',
                    ondelete => 'cascade'
                };
                push @schema,
                    sprintf( "CONSTRAINT ref_%s REFERENCES %s (id) ON DELETE cascade ON UPDATE cascade",
                    $column->{'ColName'}, $src_table->{'Tablename'} );
            }

            # ������
            if ( 'id' eq lc( $column->{'ColName'} ) ) {

                # id �ϼ�ưŪ�� ID �ˤ���
                push @schema, '/* ID */';
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable �ϼ�ưŪ�� ��� �ˤ���
                push @schema, '/* ��� */';
            }
            else {
                push @schema, sprintf( "/* %s */", $this->encode( $column->{'Comments'} ) );
            }

            # ��̾������
            $sql->{'name'} = $column->{'ColName'};

            # ��̾�ˤ�ä���̯�˥������������Ѥ���
            if ( $column->{'ColName'} eq 'id' ) {
                $sql->{'desc'} = 'ID';
            }
            elsif ( $column->{'ColName'} eq 'disable' ) {
                $sql->{'desc'} = '����ե饰';
            }
            elsif ( $column->{'ColName'} eq 'date_regist' ) {
                $sql->{'desc'} = '��Ͽ����';
            }
            elsif ( $column->{'ColName'} eq 'date_update' ) {
                $sql->{'desc'} = '��������';
            }
            else {
                $sql->{'desc'} = $this->encode( $column->{'Comments'} );

                # �������������ʤ��Ȥ��ϥ����̾����ʸ�����Ѵ�
                if ( length( $sql->{'desc'} ) == 0 ) {
                    $sql->{'desc'} = uc $column->{'ColName'};
                }
            }

            push @sqls, $sql;
            push @schemas, join( " ", @schema );
        }

        # SQL����
        my $schema_vars;
        $schema_vars->{'table'}   = $table->{'Tablename'};
        $schema_vars->{'comment'} = $this->encode( $table->{'Comments'} );
        $schema_vars->{'columns'} = join( ",\n", @schemas );
        $schema_vars->{'serials'} = join( "", @serials );
        $helper->render_file( 'schema_class', "$schema_dir/$table->{'Tablename'}.sql", $schema_vars );

        # ����ȥ������
        my $controller_vars;
        $controller_vars->{'app_name'}   = $helper->{'app'};
        $controller_vars->{'class_name'} = $class_name;
        $controller_vars->{'path_name'}  = lc $class_name;
        $controller_vars->{'comment'}    = $this->encode( $table->{'Comments'} );
        $controller_vars->{'primary'}    = $this->get_primary(@sqls);
        $controller_vars->{'columns'}    = $this->get_columns(@sqls);
        $controller_vars->{'sqls'}       = \@sqls;
        $helper->render_file( 'controller_class', "$controller_dir/$class_name.pm", $controller_vars );

        # �ƥ�ץ졼�Ƚ���
        my $path_name = lc $class_name;
        $helper->mk_dir("$template_dir/$path_name");
        $helper->render_file( 'header_html', "$template_dir/header.html", $controller_vars );
        $helper->render_file( 'footer_html', "$template_dir/footer.html", $controller_vars );
        $helper->render_file( 'create_html', "$template_dir/$path_name/create.html", $controller_vars );
        $helper->render_file( 'read_html',   "$template_dir/$path_name/read.html",   $controller_vars );
        $helper->render_file( 'update_html', "$template_dir/$path_name/update.html", $controller_vars );
        $helper->render_file( 'list_html',   "$template_dir/$path_name/list.html",   $controller_vars );
    }

    print "==========================================================\n";
}

=head1 SEE ALSO

DBDesigner 4 -- http://fabforce.net/dbdesigner4/index.php

Catalyst::Helper::Model, Catalyst::Plugin::CRUD, XML::Simple

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

__DATA__

__schema_class__
DROP TABLE [% table %];

-- [% comment %]
CREATE TABLE [% table %] (
[% columns %]
);

GRANT ALL ON [% table %] TO PUBLIC;
[% serials %]

__controller_class__
package [% app_name %]::Controller::[% class_name %];

use strict;
use warnings;
use base 'Catalyst::Controller';
use Class::Trigger;

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

sub list : Local {
    my ( $self, $c ) = @_;
    $c->list($self);
}

sub config {
    my ( $self, $c ) = @_;
    my $hash = {
        'name'     => '[% path_name %]',
        'model'    => 'DBIC::[% class_name %]',
        'primary'  => '[% primary %]',
        'columns'  => [qw([% columns %])],
        'default'  => '/[% path_name %]/list',
        'template' => {
            'prefix' => 'template/[% path_name %]/',
            'create' => 'create.html',
            'read'   => 'read.html',
            'update' => 'update.html',
            'delete' => 'delete.html',
            'list'   => 'list.html'
        },
    };
    return $hash;
}

1;

__header_html__
<html>
<head>
<title>[% app_name %]</title>
</head>
<body>

__footer_html__
<hr>
<div align="right">copyright (C) xxxx</div>
</body>
</html>

__create_html__
[% TAGS [- -] -%]
[% INCLUDE template/header.html -%]
<h1>[- comment -]�ɲ�</h1>
[% IF c.stash.create.error -%]
<font color="red">[% c.stash.create.message %]</font>
[% END -%]
<form name="[- path_name -]" method="post" action="/[- path_name -]/create">
<table>
[- FOREACH sql = sqls --]
  <tr>
    <td>[- sql.desc -]</td><td><input type="text" name="[- sql.name -]" size="25" value="[% c.req.param('[- sql.name -]') %]"></td>
  </tr>
[- END --]
  <tr>
    <td colspan="2" align="center"><input type="submit" name="submit" value="�ɲ�"></td>
  </tr>
</table>
</form>
[% INCLUDE template/footer.html -%]

__read_html__
[% TAGS [- -] -%]
[% INCLUDE template/header.html -%]
<h1>[- comment -]�ܺ�</h1>

<form>
<input type="button" name="new" value="�Խ�" onclick="javascript:window.location='/[- path_name -]/update/[% c.stash.[- path_name -].[- primary -] %]';">
</form>

<table border="1">
[- FOREACH sql = sqls --]
  <tr>
    <td>[- sql.desc -]</td><td>[% c.stash.[- path_name -].[- sql.name -] %]</td>
  </tr>
[- END --]
</table>
[% INCLUDE template/footer.html -%]

__update_html__
[% TAGS [- -] -%]
[% INCLUDE template/header.html -%]
<h1>[- comment -]�Խ�</h1>

<form name="[- path_name -]" method="post" action="/[- path_name -]/update">
<table border="1">
[- FOREACH sql = sqls --]
  <tr>
    <td>[- sql.desc -]</td><td><input type="text" name="[- sql.name -]" value="[% c.stash.[- path_name -].[- sql.name -] %]"></td>
  </tr>
[- END --]
  <tr>
    <td colspan="2" align="center"><input type="submit" name="submit" value="����"></td>
  </tr>
</table>
</form>
[% INCLUDE template/footer.html -%]

__list_html__
[% TAGS [- -] -%]
[% INCLUDE template/header.html -%]
<h1>[- comment -]����</h1>

<form>
<input type="button" name="new" value="����" onclick="javascript:window.location='/[- path_name -]/create';">
</form>

<table border="1">
<tr>
  <th>ID</th>
  <th>�ܺ�</th>
  <th>�Խ�</th>
  <th>���</th>
</tr>
[% FOREACH [- path_name -] = c.stash.[- path_name -]s -%]
<tr>
  <td>[% [- path_name -].[- primary -] %]</td>
  <td><a href="/[- path_name -]/read/[% [- path_name -].[- primary -] %]">�ܺ�</a></td>
  <td><a href="/[- path_name -]/update/[% [- path_name -].[- primary -] %]">�Խ�</a></td>
  <td><a href="/[- path_name -]/delete/[% [- path_name -].[- primary -] %]">���</a></td>
</tr>
[% END -%]
</table>
[% INCLUDE template/footer.html -%]
