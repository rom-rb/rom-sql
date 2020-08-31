---
position: 3
chapter: SQL
sections:
  - relations
  - schemas
  - queries
  - attributes
  - associations
  - joins
  - transactions
  - migrations
  - advanced-pg-support
---

$TOC
  1. [Installing](#installing)
  2. [Connecting to a Database](#connecting-to-a-database)
  3. [PostgreSQL](#postgresql)
  4. [MySQL](#mysql)
  5. [SQLite](#sqlite)
  6. [Oracle](#oracle)
  8. [Others](#others)
  9. [JRuby](#jruby)
$TOC

ROM supports SQL databases via the <mark>rom-sql</mark> adapter which augments
and enhances `Relation`. <mark>rom-sql</mark> supports a sql-specific query DSL
and association macros that simplify constructing joins and exposes the
flexibility & power of the RDMS to relation users.

Direct interactions between the database and ROM happen through the use of
the excellent [Sequel](http://sequel.jeremyevans.net/) gem by Jeremy Evans.
However, Sequel is an implementation detail of ROM and as such should not be
relied upon for functionality. If <mark>rom-sql</mark> is missing functionality
that can be accomplished in Sequel then please leave a report in our [issue
tracker](https://github.com/rom-rb/rom-rb.org/issues).

^INFO
  The SQL Adapter documentation is still being created & revised. If something
  isn't documented or requires more information, please click the  "Provide
  Feedback" buttons at the bottom of the pages and let us know. In the mean time
  you may need to look towards
  [Sequel's](http://sequel.jeremyevans.net/documentation.html) Databases &
  Datasets documentation for further guidance.
^

## Installing

*Depends on:* `ruby v2.4.0` or greater

To install <mark>rom-sql</mark> add the following to your
<mark>Gemfile</mark>.

```ruby
gem 'rom',     '~> 5.2'
gem 'rom-sql', '~> 3.2'
```

Afterwards either load `rom-sql` through your bundler setup or manually in your custom
script like so:

```ruby
require 'rom-sql'
```

Once loaded the SQL Adapter will register itself with ROM and become available
for immediate use via the `:sql` identifier.

^INFO
  Each database type requires a separate driver gem to also be installed.
  Be sure to check out the documentation of your preferred database for
  more information.
^

## Connecting to a Database

Configuring ROM and opening a connection to a database requires three parts.

  1. The name of an adapter,
  2. a connection string, and
  3. any additional options

The adapter name for the SQL Adapter is always <mark>:sql</mark> which makes
things easy; whereas connection strings are database driver specific. Connection
strings tell the SQL Adapter which driver to use for the connection along with
the port and host address of the database server. Connection strings can also
be used to set most of the available options, however it's generally better to
keep the connection string short and focused on network routing. Additional
options can be provided in a convenient hash structure or by named parameters
on the configuration method signature.

An example of this can be seen below:

```ruby
  opts = {
    username: 'postgres',
    password: 'postgres',
    encoding: 'UTF8'
  }

  # Options Hash
  config = ROM::Configuration.new(:sql, 'postgres://localhost:5432/mydbname', opts)

  # Named Parameters
  config = ROM::Configuration.new(:sql, 'postgres://localhost/mydbname', port: 5432)
```

#### General Connection Options

Options below are available to all database drivers and can be used to
configure the connection between ROM and the database.

<table>
<thead>
  <tr>
    <th>Option</th>
    <th>Value Type</th>
    <th>Description</th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>:database</td>
    <td>String</td>
    <td>Name of the database to open after successful connection.</td>
  </tr>

  <tr>
    <td>:user</td>
    <td>String</td>
    <td>Name of the user account to use when logging in.</td>
  </tr>

  <tr>
    <td>:password</td>
    <td>String</td>
    <td>Password that matches the user account.</td>
  </tr>

  <tr>
    <td>:adapter</td>
    <td>Symbol</td>
    <td>
      Sets the database driver which should be used when making a connection.
      This option is only to be used in situations where a connection string
      is <strong>NOT</strong> provided to the ROM Configuration instance.

      <h5>Available Options:</h5>
      <ul>
        <li>:postgres</li>
        <li>:sqlite</li>
        <li>:oracle</li>
        <li>:mysql</li>
      </ul>
    </td>
  </tr>

  <tr>
    <td>:host</td>
    <td>String</td>
    <td>
      Internet location of the database server. This option is <strong>required</strong>
      when the adapter option is being used.
    </td>
  </tr>

  <tr>
    <td>:port</td>
    <td>Integer</td>
    <td>Port number used during connection.</td>
  </tr>

  <tr>
    <td>:max_connections</td>
    <td>Integer</td>
    <td>The maximum number of connections the connection pool will open (default 4).</td>
  </tr>

</tbody>
</table>

### PostgreSQL

*Requires:* `pg` gem <br>
*Recommends:* `sequel_pg` gem in addition to `pg` gem

The only supported structure for connecting to PostgreSQL databases is the
Connection String URI format:

```
'postgres://[user[:password]@][host][:port][,...][/database][?param1=value1&...]'
```

For more detailed information on connections strings see the PostgreSQL
[Connection URI](https://www.postgresql.org/docs/current/static/libpq-connect.html#idm46046870061920)
documentation along with the Sequel
[Opening Databases: Postgres](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-postgres)
documentation page.

#### Quick Connect

```ruby
  opts = {
    username: 'postgres',
    password: 'postgres',
    encoding: 'UTF8'
  }
  config = ROM::Configuration.new(:sql, 'postgres://localhost/database_name', opts)
```

##### Additional Options

<table>
<thead>
  <tr>
    <th>Option</th>
    <th>Description</th>
    <th>Value Type</th>
    <th>Default Value</th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>:search_path</td>
    <td>Sets the schema search path.</td>
    <td>String, Array&lt;String&gt;</td>
    <td>['$user', 'public']</td>
  </tr>

  <tr>
    <td>:encoding</td>
    <td>
      Sets the <i>client_encoding</i> option in Postgres. Available options are
      <mark>'auto'</mark> or any encoding in the Postgres supported
      <a href="https://www.postgresql.org/docs/9.0/static/multibyte.html#CHARSET-TABLE">Charset Table</a>.
      The most common option being <code>'UTF8'</code>
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:connect_timeout</td>
    <td>Set the number of seconds to wait for a connection</td>
    <td>Integer</td>
    <td>20</td>
  </tr>

  <tr>
    <td>:driver_options</td>
    <td>Symbolized keys hash of options that are passed to the <mark>pg</mark> gem</td>
    <td>Hash</td>
    <td></td>
  </tr>

  <tr>
    <td>:sslmode</td>
    <td>
      Determines the priority or whether or not an SSL TCP/IP connection is to
      be made.

      <h5> Available Options:</h5>
      <ul>
        <li>
          <mark>'disable'</mark>
          - Only try non-SSL Connections
        </li>

        <li>
          <mark>'allow'</mark>
          - first try a non-SSL connection; if that fails, try an SSL connection
        </li>

        <li>
          <mark>'prefer'</mark>
          - first try an SSL connection; if that fails, try a non SSL connection
        </li>

        <li>
          <mark>'require'</mark>
          - only try an SSL connection. If a root CA file is present, verify the
            certificate in the same way as if verify-ca was specified
        </li>

        <li>
          <mark>'verify-ca'</mark>
          - only try an SSL connection, and verify that the server certificate is
            issued by a trusted certificate authority (CA)
        </li>

        <li>
          <mark>'verify-full'</mark>
          - only try an SSL connection, verify that the server certificate is
            issued by a trusted CA and that the requested server host name matches
            that in the certificate
        </li>
      </ul>
    </td>
    <td>String</td>
    <td>'disable'</td>
  </tr>

  <tr>
    <td>:sslrootcert</td>
    <td>Path to the root SSL certificate to use.</td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:use_iso_data_format</td>
    <td>When enabled, Sequel will ensure the ISO 8601 date format is used.</td>
    <td>Boolean</td>
    <td>true</td>
  </tr>

  <tr>
    <td>:convert_infinite_timestamps</td>
    <td>
      Determines if infinite timestamps/dates will be converted. By default, an
      error is raised and no conversion is done.

      <h5> Available Options:</h5>
      <ul>
        <li>
          <mark>:nil</mark>
          - Converts the timestamp to nil
        </li>

        <li>
          <mark>:string</mark>
          - Leaves the timestamp as a string
        </li>

        <li>
          <mark>:float</mark>
          - Converts to an infinite float
        </li>
      </ul>
    </td>
    <td>Symbol</td>
    <td>true</td>
  </tr>

</tbody>
</table>

### MySQL

*Requires:* `mysql` or `mysql2` gems <br>
*Recommends:* using `mysql2` gem

MySQL2 driver connection string uses the following pattern:

```
'mysql2://[user[:password]@][host][:port][/database][?param1=value1&...]'
```

For more detailed information on connecting to a MySQL database
see the [MySQL2](https://github.com/brianmario/mysql2) project site

#### Quick Connect

```ruby
  opts = {
    encoding: 'UTF8'
  }
  config = ROM::Configuration.new(:sql, 'mysql2://localhost/database_name', opts)
```

##### Additional Options

<table>
<thead>
  <tr>
    <th>Option</th>
    <th>Description</th>
    <th>Value Type</th>
    <th>Default Value</th>
  </tr>
</thead>
<tbody>

  <tr>
    <td>:encoding</td>
    <td>
      Specify the encoding/character set to use for the connection. Available
      encodings can be found in the MySQL
      <a href="https://dev.mysql.com/doc/refman/5.7/en/charset-charsets.html">Charset Table</a>.
      The most common option being <mark>'UTF8'</mark>
    </td>
    <td>String</td>
    <td>'UTF8'</td>
  </tr>

  <tr>
    <td>:write_timeout</td>
    <td>
      Set the timeout in seconds when writing to the database.
    </td>
    <td>Integer</td>
    <td></td>
  </tr>

  <tr>
    <td>:read_timeout</td>
    <td>
      Set the timeout in seconds when reading query results.
    </td>
    <td>Integer</td>
    <td></td>
  </tr>

  <tr>
    <td>:connect_timeout</td>
    <td>
      Set the timeout in seconds before a connection attempt is abandoned.
    </td>
    <td>Integer</td>
    <td></td>
  </tr>

  <tr>
    <td>Boolean</td>
    <td>
      When enabled the server will refuse connection if the
      account password is stored in old pre-MySQL 4.1 format.
    </td>
    <td>:secure_auth</td>
    <td>true</td>
  </tr>

  <tr>
    <td>:sql_mode</td>
    <td>
      Sets the sql_mode(s) for a given connection.
      eg: <mark>[:no_zero_date, :pipes_as_concat]</mark>

      <p>
        Available sql_modes can be found in MySQL
        <a href="https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sql-mode-full">Server SQL Modes</a>
        documentation.
      </p>
    </td>
    <td>Array&lt;String, Symbol&gt;, String, Symbol</td>
    <td></td>
  </tr>

  <tr>
    <td>:flags</td>
    <td>
      Flags added to an array are added to the Default flags, while flags with a
      <mark>-</mark> (minus) prefix are removed from the default flags.

      For more information see <a href="https://github.com/brianmario/mysql2#flags-option-parsing">Flag Option Parsing</a>.

      <h5> Available Options:</h5>
      <ul>
        <li>'REMEMBER_OPTIONS'</li>
        <li>'LONG_PASSWORD'</li>
        <li>'LONG_FLAG'</li>
        <li>'TRANSACTIONS'</li>
        <li>'PROTOCOL_41'</li>
        <li>'SECURE_CONNECTION'</li>
        <li>'MULTI_STATEMENTS'</li>
      </ul>
    </td>
    <td>String, Array&lt;String&gt;</td>
    <td></td>
  </tr>

  <tr>
    <td>:socket</td>
    <td>
      Used to specify a Unix socket file to connect to instead of a TCP host & port.
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:sslmode</td>
    <td>
      Determines the priority or whether or not a SSL TCP/IP connection is to
      be made.

      <h5> Available Options:</h5>
      <ul>
        <li>
          <mark>:disabled</mark>
          - Establish an unencrypted connection
        </li>

        <li>
          <mark>:preferred</mark>
          - First try a non-SSL connection; if that fails, try an SSL connection
        </li>

        <li>
          <mark>:required</mark>
          - Establish a secure connection if the server supports secure connections
        </li>

        <li>
          <mark>:verify_ca</mark>
          - Only establish an SSL connection and verify the servers TLS certificate
            against the configured Certificate Authority (CA) certificates.
        </li>

        <li>
          <mark>:verify_identity</mark>
          - Like <mark>:verify_ca</mark>, but additionally verify the server
            certificate matches the host to which the connection is attempted.
        </li>
      </ul>
    </td>
    <td>Symbol</td>
    <td>:disabled</td>
  </tr>

  <tr>
    <td>:sslkey</td>
    <td>
      Path to the client key. eg: <mark>'path/to/client-key.pem'</mark>
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:sslcert</td>
    <td>
      Path to the client certificate. eg: <mark>'path/to/client-cert.pem'</mark>
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:sslca</td>
    <td>
      Path to the CA certificate. eg: <mark>'/path/to/ca-cert.pem'</mark>
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:sslcapath</td>
    <td>
      Path to the CA certificates. eg. <mark>'path/to/cacerts'</mark>
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:sslcipher</td>
    <td>
      Supported ciphers can be found in the MySQL
      <a href="https://dev.mysql.com/doc/refman/5.7/en/encrypted-connection-protocols-ciphers.html">Encrypted Connection Protocols</a>
      document. eg: <mark>'DHE-RSA-AES256-SHA'</mark>
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:sslverify</td>
    <td>
      When set to <mark>true</mark>, the server is required to present a valid
      certificate.
    </td>
    <td>Boolean</td>
    <td>false</td>
  </tr>
</tbody>
</table>

### SQLite

*Requires:* `sqlite3` gem

SQLite is a self contained in-process database that supports loading databases
from files located on the file system or by creating and running the database
completely in-memory.

Documentation on the connection string format has been skipped for this database driver as there
are no configuration options supported through the uri. The below
[Quick Connect](#quick-connect_2) examples should offer enough information on how to connect
to this type of database.

^INFO
  By default a SQLite in-memory database is restricted to a single connection.
  This is a restriction imposed by SQLite itself and for this reason,
  Sequel sets the maximum number of connections in the connection pool to `1`.
  Overriding the connection pool limit will result in weird behavior as new
  connections will be to separate memory databases.

For more information see
[Sequel's SQLite](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-sqlite)
documentation or for URI file formats see
[URI Filenames in SQLite](https://www.sqlite.org/uri.html)
^

#### Quick Connect

```ruby
  opts = {
    readonly: true
  }

  # Absolute path examples
  config = ROM::Configuration.new(:sql, 'sqlite://path/to/db-file.db', opts)
  config = ROM::Configuration.new(:sql, 'sqlite://C:/databases/db-file.db', opts)
  config = ROM::Configuration.new(:sql, 'sqlite:///var/sqlite/db-file.db', opts)

  # Relative path examples
  config = ROM::Configuration.new(:sql, 'sqlite://db-file.db', opts)
  config = ROM::Configuration.new(:sql, 'sqlite://../db-file.db', opts)

  # In-memory database example
  config = ROM::Configuration.new(:sql, 'sqlite::memory', opts)
```

##### Additional Options

<table>
<thead>
  <tr>
    <th>Option</th>
    <th>Description</th>
    <th>Value Type</th>
    <th>Default Value</th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>:database</td>
    <td>
      Path to the SQLite database file.
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:host</td>
    <td>
      This option is ignored.
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:port</td>
    <td>
      This option is ignored.
    </td>
    <td>String</td>
    <td></td>
  </tr>

  <tr>
    <td>:readonly</td>
    <td>
      Opens the database in read-only mode
    </td>
    <td>Boolean</td>
    <td>false</td>
  </tr>

  <tr>
    <td>:timeout</td>
    <td>
      Busy timeout in milliseconds
    </td>
    <td>Integer</td>
    <td>5000</td>
  </tr>

</tbody>
</table>

### Oracle

*Requires:* `ruby-oci8` gem

OCI8 driver connection strings use the following pattern:

```
'oracle://[user[:password]@][host][:port][/database][?param1=value1&...]'
```

#### Quick Connect

```ruby
  opts = {
    autosequence: true
  }
  config = ROM::Configuration.new(:sql, 'oracle://localhost/database_name', opts)
```

##### Additional Options

<table>
<thead>
  <tr>
    <th>Option</th>
    <th>Description</th>
    <th>Value Type</th>
    <th>Default Value</th>
  </tr>
</thead>
<tbody>

  <tr>
    <td>:autosequence</td>
    <td>
      When <mark>true</mark> Sequel's conventions will be used to guess the
      sequence to use for the dataset.
    </td>
    <td>Boolean</td>
    <td>false</td>
  </tr>

  <tr>
    <td>:prefetch_rows</td>
    <td>
      Number of rows to prefetch. Larger numbers can be specified which
      may improve performance when retrieving large numbers of rows.
    </td>
    <td>Integer</td>
    <td>100</td>
  </tr>

  <tr>
    <td>:privilege</td>
    <td>
      Oracle privilege level.
      <h5>Available Options:</h5>
      <ul>
        <li>:SYSDBA</li>
        <li>:SYSOPER</li>
        <li>:SYSASM</li>
        <li>:SYSBACKUP</li>
        <li>:SYSDG</li>
        <li>:SYSKM</li>
      </ul>
    </td>
    <td>String</td>
    <td></td>
  </tr>

</tbody>
</table>

### Others

The SQL Adapter supports other drivers and URI connection schemes outside the
ones documented here.

- `ado`
- `amalgalite`
- `cubrid`
- `db2`
- `dbi`
- `do`
- `fdbsql`
- `firebird`
- `ibmdb`
- `informix`
- `mysql`
- `odbc`
- `openbase`
- `sqlanywhere`
- `swift`
- `tinytds`

These drivers have not been documented because their use is fairly uncommon
however they should work and documentation for connecting with each of these
drivers can be found in Sequel's
[Opening Databases](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html)
document.

### JRuby

*Requires:* `java`, & the `jruby` runtime

In a JRuby environment, it's best to use the `JDBC` driver available to
you via the Java SDK. Support for databases in JRuby is handled via
Sequel's JDBC sub adapters.

A list of supported databases can be found below along with additional
requirements:

| Database   | Required Gem     |
| ---------- | ---------------- |
| Derby      | jdbc-derby       |
| H2         | jdbc-h2          |
| HSQLDB     | jdbc-hsqldb      |
| JTDS       | jdbc-jtds        |
| MySQL      | jdbc-mysql       |
| PostgreSQL | jdbc-postgres    |
| SQLite     | jdbc-sqlite3     |

For the databases `DB2`, `Oracle` & `SQL Server`, the `.jar` file will need
to either be in your `CLASSPATH` or manually preloaded before making a
connection.

Connection strings are similar to their documented patterns above however all
connection strings must start with `jdbc:` for example:

```
# Postgres Example
jdbc:postgresql://username@localhost/database

# MySQL Example
jdbc:mysql://localhost/database?user=root&password=root

# SQLite Example
jdbc:sqlite::memory
```

For more information see
[Sequel's JDBC](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-jdbc+)
and
[Java SE - Database](http://www.oracle.com/technetwork/java/javase/jdbc/index.html)
documentation

<!--

Future addition should include configuring sequel and extensions

 ### Configuring Sequel

```ruby
Sequel.application_timezone = :utc
```

-->
