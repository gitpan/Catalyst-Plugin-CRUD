package Catalyst::Helper::Model::CRUD;

use strict;
use Jcode;
use XML::Simple;

our $VERSION = '0.07';

=head1 NAME

Catalyst::Helper::Model::CRUD - generate sqls, controllers and templates from DBDesigner 4 file

=head1 SYNOPSIS

    ./myapp_create.pl model DBIC CRUD [DBDesigner 4 File] [some modules]

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
    for ( my $i = 0 ; $i < scalar(@array) ; $i++ ) {

        # translate "\\n" to "。"
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
    for ( my $i = 0 ; $i < scalar(@array) ; $i++ ) {
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

=head2 get_setting_index($array, $name)

get appointed name's setting number

=cut

sub get_setting_index {
    my ( $this, $array, $name ) = @_;
    for ( my $i = 0 ; $i < scalar( @{$array} ) ; $i++ ) {
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

    # ファイル名は必須
    unless ($file) {
        die "usage: ./myapp_create.pl model CRUD CRUD [DBDesigner 4 File] [some modules]\n";
        return 1;
    }

    # XMLファイル解析
    my $parser = new XML::Simple();
    my $tree   = $parser->XMLin($file);

    # SQL・コントローラ・テンプレート用のディレクトリを作る
    my $setting_dir    = sprintf( "%s/sql/setting",       $helper->{'base'} );
    my $i18n_dir       = sprintf( "%s/lib/%s/I18N",       $helper->{'base'}, $helper->{'app'} );
    my $controller_dir = sprintf( "%s/lib/%s/Controller", $helper->{'base'}, $helper->{'app'} );
    my $template_dir   = sprintf( "%s/root/template",     $helper->{'base'} );
    $helper->mk_dir($setting_dir);
    $helper->mk_dir($i18n_dir);
    $helper->mk_dir($controller_dir);
    $helper->mk_dir($template_dir);

    # リレーションとテーブル一覧を取得する
    if ( ref $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} eq 'ARRAY' ) {
        @relations = @{ $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} };
    }
    else {
        push( @relations, $tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'} );
    }
    if ( ref $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} eq 'ARRAY' ) {
        @tables = @{ $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} };
    }
    else {
        push( @tables, $tree->{'METADATA'}->{'TABLES'}->{'TABLE'} );
    }

    # 指定したモジュールのみ
    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    foreach my $table (@tables) {
        my $class_name = $this->get_class_name( $table->{'Tablename'} );

        # 指定したモジュールのみ
        if ( scalar @limited_file ) {
            next unless ( $limit{$class_name} );
        }

        # 各テーブルの列一覧取得
        my @columns = @{ $table->{'COLUMNS'}->{'COLUMN'} }
          if ref $table->{'COLUMNS'}->{'COLUMN'} eq 'ARRAY';

        # 各テーブルのインデックス覧取得
        my %indices;
        if ( ref( $table->{'INDICES'}->{'INDEX'} ) eq 'HASH' ) {

            # 要素一個のときはハッシュになってしまうのでその対策
            my $key = $table->{'INDICES'}->{'INDEX'}->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
            my $val = $table->{'INDICES'}->{'INDEX'}->{'FKRefDef_Obj_id'};

            # 主キーは無視する
            unless ( $val eq '-1' ) {
                $indices{$key} = $val;
            }
        }
        elsif ( ref( $table->{'INDICES'}->{'INDEX'} ) eq 'ARRAY' ) {
            foreach my $index ( @{ $table->{'INDICES'}->{'INDEX'} } ) {
                my $key = $index->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
                my $val = $index->{'FKRefDef_Obj_id'};

                # 主キーは無視する
                unless ( $val eq '-1' ) {
                    $indices{$key} = $val;
                }
            }
        }

        my @serials;     # シーケンス一覧
        my @sqls;        # SQL一覧
        my @settings;    # スキーマ一覧
        foreach my $column (@columns) {
            my $sql;
            my @setting;

            # カラム名
            push @setting, ( "        " . $column->{'ColName'} );

            # 型
            if ( $column->{'AutoInc'} eq "1" ) {

                # AutoInc="1" だったら「テーブル名_カラム名_seq」という
                # テーブルを Postgresql が自動作成するのでその対応
                $sql->{'type'} = "serial";
                push @setting, "SERIAL";
                push @serials,
                  sprintf( "GRANT ALL ON %s_%s_seq TO PUBLIC;\n", $table->{'Tablename'}, $column->{'ColName'} );
            }
            elsif ( $column->{'idDatatype'} eq '5' ) {
                $sql->{'type'} = "int";
                push @setting, "INTEGER";
            }
            elsif ( $column->{'idDatatype'} eq '14' ) {
                $sql->{'type'} = "date";
                push @setting, "DATE";
            }
            elsif ( $column->{'idDatatype'} eq '16' ) {
                $sql->{'type'} = "timestamp with time zone";
                push @setting, "TIMESTAMP with time zone";
            }
            elsif ( $column->{'idDatatype'} eq '20' ) {
                $sql->{'type'} = "varchar(255)";
                push @setting, "VARCHAR(255)";
            }
            elsif ( $column->{'idDatatype'} eq '22' ) {
                $sql->{'type'} = "bool";
                push @setting, "BOOL";
            }
            elsif ( $column->{'idDatatype'} eq '28' ) {
                $sql->{'type'} = "text";
                push @setting, "TEXT";
            }
            else {
                $sql->{'type'} = "text";
                push @setting, "TEXT";
            }

            # 主キーかどうか
            if ( $column->{'PrimaryKey'} eq '1' ) {
                $sql->{'primarykey'} = 1;
                push @setting, "PRIMARY KEY";
            }
            elsif ( 'id' eq lc( $column->{'ColName'} ) ) {

                # id は自動的に主キーにする
                $sql->{'primarykey'} = 1;
                push @setting, "PRIMARY KEY";
            }

            # デフォルト値
            if ( length( $column->{'DefaultValue'} ) > 0 ) {
                $sql->{'default'} = $column->{'DefaultValue'};
                push @setting, sprintf( "DEFAULT '%s'", $column->{'DefaultValue'} );
            }
            elsif ( $column->{'idDatatype'} eq '14' ) {

                # 日付は自動的に設定する
                $sql->{'default'} = "('now'::text)::timestamp";
                push @setting, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( $column->{'idDatatype'} eq '16' ) {

                # 日時は自動的に設定する
                $sql->{'default'} = "('now'::text)::timestamp";
                push @setting, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に 0 にする
                $sql->{'default'} = "0";
                push @setting, "DEFAULT '0'";
            }

            # NOT NULL 制約
            if ( $column->{'NotNull'} eq '1' ) {
                $sql->{'notnull'} = 1;
                push @setting, "NOT NULL";
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に NOT NULL にする
                $sql->{'notnull'} = 1;
                push @setting, "NOT NULL";
            }

            # 参照制約
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
                push @setting,
                  sprintf( "CONSTRAINT ref_%s REFERENCES %s (id) ON DELETE cascade ON UPDATE cascade",
                    $column->{'ColName'}, $src_table->{'Tablename'} );
            }

            # コメント
            if ( 'id' eq lc( $column->{'ColName'} ) ) {

                # id は自動的に ID にする
                push @setting, '/* ID */';
            }
            elsif ( 'disable' eq lc( $column->{'ColName'} ) ) {

                # disable は自動的に 削除 にする
                push @setting, '/* 削除 */';
            }
            else {
                push @setting, sprintf( "/* %s */", $this->encode( $column->{'Comments'} ) );
            }

            # 列名の代入
            $sql->{'name'} = $column->{'ColName'};

            # 列名によって微妙にカラムの説明を変える
            if ( $column->{'ColName'} eq 'id' ) {
                $sql->{'desc'} = 'ID';
            }
            elsif ( $column->{'ColName'} eq 'disable' ) {
                $sql->{'desc'} = '削除フラグ';
            }
            elsif ( $column->{'ColName'} eq 'date_regist' ) {
                $sql->{'desc'} = '登録日時';
            }
            elsif ( $column->{'ColName'} eq 'date_update' ) {
                $sql->{'desc'} = '更新日時';
            }
            else {
                $sql->{'desc'} = $this->encode( $column->{'Comments'} );

                # カラムの説明がないときはカラム名を大文字に変換
                if ( length( $sql->{'desc'} ) == 0 ) {
                    $sql->{'desc'} = uc $column->{'ColName'};
                }
            }

            push @sqls, $sql;
            push @settings, join( " ", @setting );
        }

        # SQL出力
        my $setting_vars;
        $setting_vars->{'table'}   = $table->{'Tablename'};
        $setting_vars->{'comment'} = $this->encode( $table->{'Comments'} );
        $setting_vars->{'columns'} = join( ",\n", @settings );
        $setting_vars->{'serials'} = join( "", @serials );
        $helper->render_file( 'setting_class', "$setting_dir/$table->{'Tablename'}.sql", $setting_vars );

        # コントローラ出力
        my $controller_vars;
        $controller_vars->{'app_name'}   = $helper->{'app'};
        $controller_vars->{'path_name'}  = lc $class_name;
        $controller_vars->{'model_name'} = $helper->{'name'};
        $controller_vars->{'class_name'} = $class_name;
        $controller_vars->{'comment'}    = $this->encode( $table->{'Comments'} );
        $controller_vars->{'primary'}    = $this->get_primary(@sqls);
        $controller_vars->{'columns'}    = $this->get_columns(@sqls);
        $controller_vars->{'sqls'}       = \@sqls;
        $helper->render_file( 'controller_class', "$controller_dir/$class_name.pm", $controller_vars );

        # テンプレート出力
        my $path_name = lc $class_name;
        $helper->mk_dir("$template_dir/$path_name");
        $helper->render_file( 'header_html', "$template_dir/header.html",            $controller_vars );
        $helper->render_file( 'footer_html', "$template_dir/footer.html",            $controller_vars );
        $helper->render_file( 'create_html', "$template_dir/$path_name/create.html", $controller_vars );
        $helper->render_file( 'read_html',   "$template_dir/$path_name/read.html",   $controller_vars );
        $helper->render_file( 'update_html', "$template_dir/$path_name/update.html", $controller_vars );
        $helper->render_file( 'list_html',   "$template_dir/$path_name/list.html",   $controller_vars );
    }

    # 言語ファイル出力
    $helper->render_file( 'ja_po', "$i18n_dir/ja.po" );
    $helper->render_file( 'en_po', "$i18n_dir/en.po" );

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

__setting_class__
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

#sub create : Local {
#    my ( $self, $c ) = @_;
#    $c->create($self);
#}

#sub read : Local {
#    my ( $self, $c ) = @_;
#    $c->read($self);
#}

#sub update : Local {
#    my ( $self, $c ) = @_;
#    $c->update($self);
#}

#sub delete : Local {
#    my ( $self, $c ) = @_;
#    $c->delete($self);
#}

sub list : Local {
    my ( $self, $c ) = @_;
    $c->list($self);
}

sub setting {
    my ( $self, $c ) = @_;
    my $hash = {
        'name'     => '[% path_name %]',
        'model'    => '[% model_name %]::[% class_name %]',
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
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja">
  <head>
    <meta http-equiv="content-type" content="application/xhtml+xml; charset=euc-jp" />
    
    <title>[% app_name %]</title>
    
    <style type="text/css">
    <!--
    /* ###### Browser-specific Styles ###### */
    
    /* For IE & Mozilla-based browsers: */
    
    .LHS {
      margin-left: 2.5mm;
      float: left;
      clear: left;
    }
    
    .RHS {
      margin-right: 2.5mm;
      float: right;
      clear: right;
    }
    
    /* For Mozilla-based (CSS2-fully complaint) browsers only: */
    
    [class~="LHS"] {
      margin-left: 5mm;
    }
    
    [class~="RHS"] {
      margin-right: 5mm;
    }
    
    /* ###### Body Text ###### */
    
    body {
      background-color: white;
      color: black;
      font-family: verdana, tahoma, helvetica, arial, sans-serif;
      font-size: 95%;
      margin: 0;
      background-repeat: no-repeat;
      background-attachment: scroll;
    }
    
    h1, h2, h3 {
      font-family: "trebuchet ms", tahoma, sans-serif;
    }
    
    h1 {
      font-weight: bold;
      font-size: 150%;
      border-bottom-style: solid;
      border-bottom-width: 1px;
      padding-bottom: 0.5ex;
    }
    
    img {
      border: none;
    }
    
    q {
      font-family: tahoma, verdana, helvetica, arial, sans-serif;
      font-weight: bold;
      border-style: dotted;
      border-width: 2px;
      margin: 0 1em 1ex 1em;
      padding: 0.5ex 0.5ex 0.5ex 1ex;
      width: 9em;
      float: left;
    }
    
    acronym {
      border-bottom-style: dotted;
      border-bottom-width: 1px;
      cursor: help;
    }
    
    code {
      font-family: "lucida console", monospace;
      font-size: 90%;
    }
    
    dt {
      font-weight: bold;
    }
    
    dd {
      padding-bottom: 1.5em;
    }
    
    #bodyText {
      text-align: justify;
      line-height: 1.5em;
      margin: 10mm 5mm 0 14em;
      padding: 0 1em 1ex 1em;
    }
    
    #bodyText p {
      padding-bottom: 2ex;
    }
    
    #bodyText a {
      text-decoration: none;
      border-bottom-style: solid;
      border-bottom-width: 1px;
    }
    
    #bodyText a:hover {
      border-bottom: none;
    }
    
    #bodyText .topOfPage {
      font-size: 90%;
      font-weight: bold;
      font-variant: small-caps;
      text-decoration: none;
      border: none;
      padding-left: 1ex;
      padding-right: 1ex;
      float: right;
    }
    
    .smallCaps {
      font-variant: small-caps;
    }
    
    /* ###### Header ###### */
    
    #header {
      border-bottom-style: solid;
      border-bottom-width: 2px;
      height: 7.5em;
      margin-bottom: 5mm;
      padding: 0 2.5mm 0 5mm;
      background-repeat: no-repeat;
    }
    
    .headerTitle {
      font-size: 300%;
      font-weight: bold;
      line-height: 2em;
    }
    
    .menuBar {
      float: left;
    }
    
    .locBar {
      float: right;
    }
    
    .menuBar *, .locBar * {
      text-decoration: none;
      font-weight: bold;
      padding-right: 1ex;
    }
    
    .menuBar a:hover, .locBar a:hover {
      text-decoration: underline;
    }
    
    /* ###### Side Box ###### */
    
    .sideBox {
      border-style: solid none solid none;
      border-width: 2px 0 2px 0;
      width: 11em;
      margin-top: 5mm;
    }
    
    .sideBox div {
      font-weight: bold;
      border-bottom-style: dashed;
      border-bottom-width: 1px;
      padding: 0.5ex 0.5em 0.5ex 0.75em;
    }
    
    .sideBox a, .sideBox a:hover, .sideBox span {
      color: black;
      text-decoration: none;
      line-height: 1.25em;
      display: block;
      padding: 1.25ex 0.5em 1.25ex 0.75em;
    }
    
    .sideBox .thisPage {
      font-weight: bold;
    }
    
    /* ###### Footer ###### */
    
    #footer {
      padding-top: 0.75ex;
      padding-bottom: 0.75ex;
      clear: left;
    }
    
    #footer div {
      font-size: 85%;
      line-height: 1.25em;
      text-align: right;
      padding-right: 3mm;
    }
    
    #footer a:hover {
      text-decoration: none;
    }
    
    .footerLHS {
      float: left;
      clear: left;
      padding-left: 3mm;
    }
    
    /* ###### General Color Scheme ###### */
    
    h1, h2, h3, q, #header div, #header div *, #footer *, .headerTitle, .sideBox div, .topOfPage
    { /* Text Color: */  color: #4080ff; }
    
    h1, q,  #header, .sideBox, .sideBox div
    { /* Border Color: */  border-color: #0080ff; }
    
    #header, .sideBox div, .sideBox a:hover, .sideBox .thisPage
    { /* Background Color (darker): */  background-color: #e8f0ff; }
    
    q, .sideBox a, .sideBox span
    { /* Background Color (lighter): */  background-color: #fafcff; }
    
    /* ###### Special Colors ###### */
    
    acronym {
      color: blue;
      border-bottom-color: blue;
    }
    
    #bodyText a {
      color: #4080ff;
      border-bottom-color: #4080ff;
    }
    
    #footer {
      background-color: #f2f6ff;
    }
    -->
    </style>
  </head>

  <body>
    <div id="top"></div>

    <!-- ###### Header ###### -->

    <div id="header">
      <span class="headerTitle">[% app_name %]</span>
      <div class="menuBar">
        <a href="/">Home</a>|
        <a href="#">Menu1</a>|
        <a href="#">Menu2</a>
      </div>
    </div>

    <!-- ###### Side Boxes ###### -->

    <div class="sideBox LHS">
      <div>SubMenu</div>
      <a href="#">SubMenu1</a>
      <a href="#">SbuMenu2</a>
    </div>

    <!-- ###### Body Text ###### -->

    <div id="bodyText">

__footer_html__
    </div>
    
    <!-- ###### Footer ###### -->

    <div id="footer">
      <div class="footerLHS">
        <a href="#">SiteMap</a>
      </div>
      
      <div>
        Copyright (C) 20XX xxxx yyyy.
      </div>
    </div>
  </body>
</html>

__create_html__
[% TAGS [- -] -%]
[% INCLUDE template/header.html -%]
<a class="topOfPage" href="#top" title="Top Of Page">top</a>
<h1>[- comment -][% c.loc('New') %]</h1>
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
    <td colspan="2" align="center"><input type="submit" name="btn_create" value="[% c.loc('Add') %]"></td>
  </tr>
</table>
</form>
[% INCLUDE template/footer.html -%]

__read_html__
[% TAGS [- -] -%]
[% INCLUDE template/header.html -%]
<a class="topOfPage" href="#top" title="Top Of Page">top</a>
<h1>[- comment -][% c.loc('Detail') %]</h1>

<form>
  <input type="button" name="btn_update" value="[% c.loc('Edit') %]" onclick="javascript:window.location='/[- path_name -]/update/[% c.stash.[- path_name -].[- primary -] %]';"><br/>
  <br/>
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
<a class="topOfPage" href="#top" title="Top Of Page">top</a>
<h1>[- comment -][% c.loc('Edit') %]</h1>

<form name="[- path_name -]" method="post" action="/[- path_name -]/update">
<table border="1">
[- FOREACH sql = sqls --]
  <tr>
    <td>[- sql.desc -]</td><td><input type="text" name="[- sql.name -]" size="25" value="[% c.stash.[- path_name -].[- sql.name -] %]"></td>
  </tr>
[- END --]
  <tr>
    <td colspan="2" align="center"><input type="submit" name="btn_update" value="[% c.loc('Update') %]"></td>
  </tr>
</table>
</form>
[% INCLUDE template/footer.html -%]

__list_html__
[% TAGS [- -] -%]
[% INCLUDE template/header.html -%]
<a class="topOfPage" href="#top" title="Top Of Page">top</a>
<h1>[- comment -][% c.loc('List') %]</h1>

<form>
  <input type="button" name="btn_create" value="[% c.loc('New') %]" onclick="javascript:window.location='/[- path_name -]/create';"><br/>
  <br/>
</form>

<table border="1">
<tr>
  <th>ID</th>
  <th>[% c.loc('Detail') %]</th>
  <th>[% c.loc('Edit') %]</th>
  <th>[% c.loc('Delete') %]</th>
</tr>
[% FOREACH [- path_name -] = c.stash.[- path_name -]s -%]
<tr>
  <td>[% [- path_name -].[- primary -] %]</td>
  <td><a href="/[- path_name -]/read/[% [- path_name -].[- primary -] %]">[% c.loc('Detail') %]</a></td>
  <td><a href="/[- path_name -]/update/[% [- path_name -].[- primary -] %]">[% c.loc('Edit') %]</a></td>
  <td><a href="/[- path_name -]/delete/[% [- path_name -].[- primary -] %]">[% c.loc('Delete') %]</a></td>
</tr>
[% END -%]
</table>
[% INCLUDE template/footer.html -%]

__ja_po__
msgid "New"
msgstr "新規"

msgid "Detail"
msgstr "詳細"

msgid "Edit"
msgstr "編集"

msgid "Delete"
msgstr "削除"

msgid "List"
msgstr "一覧"

msgid "Add"
msgstr "追加"

msgid "Update"
msgstr "更新"

msgid "Delete"
msgstr "削除"

__en_po__
msgid "New"
msgstr ""

msgid "Detail"
msgstr ""

msgid "Edit"
msgstr ""

msgid "Delete"
msgstr ""

msgid "List"
msgstr ""

msgid "Add"
msgstr ""

msgid "Update"
msgstr ""

msgid "Delete"
msgstr ""

