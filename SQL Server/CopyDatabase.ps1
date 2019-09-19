<#
    Экспериментальный скрипт для копирования базы данных по объектам.
    Для копирования используется SQL Servet Managment Object
    https://docs.microsoft.com/ru-ru/sql/relational-databases/server-management-objects-smo/overview-smo?view=sql-server-2017

    Этапы работы скрипта:
        1. Создаем соединения со SQL Server
        2. Создаем пустую базу данных назначения
        3. Передаем все объекты базы данных в в базу назначения (данные не передаются)
        4. Включаем сжатие для всех объектов базы данных
        5. Передаем все данные для ранее скопированных объектов
        6. Закрываем соединения со SQL Server

    TODO: Скрипт эксперементальный и не для рабочего окружения. 
    Требует серьезного рефакторинга и доработок.
#>

[string] $SourceSQLInstance = "localhost";
[string] $SourceDatabase = "source_db_name";
[string] $TargetSQLInstance = "localhost";
[string] $TargetDatabase = "target_db_name";

#$sourceConnStr = "Data Source=$SourceSQLInstance;Initial Catalog=$SourceDatabase;Integrated Security=True;"
#$TargetConnStr = "Data Source=$TargetSQLInstance;Initial Catalog=$TargetDatabase;Integrated Security=True;"
$sourceConnStr = "Data Source=$SourceSQLInstance;Initial Catalog=$SourceDatabase;User Id=<userName>;Password=<userPassword>;"
$TargetConnStr = "Data Source=$TargetSQLInstance;User Id=<userName>;Password=<userPassword>;"

Import-Module -Name SQLPS
write-host 'SQLPS module loaded'



write-host 'Connecting...'

$sourceSQLServer = New-Object Microsoft.SqlServer.Management.Smo.Server $SourceSQLInstance
$sourceDB = $sourceSQLServer.Databases[$SourceDatabase]
$sourceConn = New-Object System.Data.SqlClient.SQLConnection($sourceConnStr)
$sourceConn.Open()

$targetSQLServer = New-Object Microsoft.SqlServer.Management.Smo.Server $TargetSQLInstance
$targetDB = $sourceSQLServer.Databases[$TargetDatabase]
$targetConn = New-Object System.Data.SqlClient.SQLConnection($TargetConnStr)
$targetConn.Open()

write-host 'Connection established!'


write-host 'Creating target database...'

if ($targetDB) {
    $targetSQLServer.KillAllprocesses($TargetDatabase)
    $targetDB.Drop()
}
$targetDBNew = New-Object Microsoft.SqlServer.Management.Smo.Database($targetSQLServer, $TargetDatabase)
$targetDBNew.Create()

write-host 'Database created!'


write-host 'Transferring database objects...'

$ObjTransfer = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Transfer -ArgumentList $SourceDB

$ObjTransfer.Options.AllowSystemObjects = $false
$ObjTransfer.Options.ContinueScriptingOnError = $false
$ObjTransfer.Options.Indexes = $true
$ObjTransfer.Options.IncludeIfNotExists = $true
$ObjTransfer.Options.DriAll = $true
$ObjTransfer.Options.SchemaQualify = $true
$ObjTransfer.Options.ScriptSchema = $true
$ObjTransfer.Options.ScriptData = $true
$ObjTransfer.Options.WithDependencies = $true

$ObjTransfer.CopyAllTables = $true
$ObjTransfer.Options.WithDependencies = $true
$ObjTransfer.Options.ContinueScriptingOnError = $true
$ObjTransfer.DestinationDatabase = $TargetDatabase
$ObjTransfer.DestinationServer = $TargetSQLInstance
$ObjTransfer.DestinationLoginSecure = $true;
$ObjTransfer.CopyAllDatabaseTriggers = $true;
$ObjTransfer.CopyAllDefaults = $true;
$ObjTransfer.CopyAllFullTextCatalogs = $true;
$ObjTransfer.CopyAllFullTextStopLists = $true;
$ObjTransfer.CopyAllPartitionFunctions = $true;
$ObjTransfer.CopyAllPartitionSchemes = $true;
$ObjTransfer.CopyAllPlanGuides = $true;
$ObjTransfer.CopyAllRoles = $true;
$ObjTransfer.CopyAllRules = $true;
$ObjTransfer.CopyAllSchemas = $true;
$ObjTransfer.CopyAllSearchPropertyLists = $true;
$ObjTransfer.CopyAllSequences = $true;
$ObjTransfer.CopyAllSqlAssemblies = $true;
$ObjTransfer.CopyAllStoredProcedures = $true;
$ObjTransfer.CopyAllSynonyms = $true;
$ObjTransfer.CopyAllTables = $true;
$ObjTransfer.CopyAllUsers = $true;
$ObjTransfer.CopyAllViews = $true;
$ObjTransfer.CopyAllXmlSchemaCollections = $true;
$ObjTransfer.CopySchema = $true;
$ObjTransfer.CopyData = $false;

$ObjTransfer.TransferData()

write-host 'Database objects transferred!'





write-host 'Enabling compression for database objects...'

$targetConn.ChangeDatabase($TargetDatabase);

$cmdObjectCompression = 
"declare @table_name sys.sysname, @IS_CLUSTERED bit, @SQL nvarchar(1000)
    declare @c cursor
    set @c = cursor local fast_forward for   
    select distinct s.name + '.' + o.name, coalesce( (select 1 from sys.indexes i where o.object_id = i.object_id and i.type_desc = 'CLUSTERED' ), 0 ) IS_CLUSTERED
    from sys.partitions p
      inner join sys.objects o on p.object_id = o.object_id and o.type_desc = 'USER_TABLE' and p.partition_number = 1
      inner join sys.schemas s on s.schema_id = o.schema_id
    where p.data_compression_desc = 'NONE'
    open @c
    fetch next from @c into @table_name, @IS_CLUSTERED
    while (@@fetch_status = 0) begin
      set @sql = 'ALTER INDEX ALL ON ' + @table_name + ' REBUILD WITH (DATA_COMPRESSION = PAGE);' -- DATA_COMPRESSION = PAGE / DATA_COMPRESSION = NONE
      execute (@sql)
      print @sql
      if ( @IS_CLUSTERED = 0 ) begin
        set @sql = 'ALTER TABLE ' + @table_name + ' REBUILD WITH (DATA_COMPRESSION = PAGE);' -- DATA_COMPRESSION = PAGE / DATA_COMPRESSION = NONE
        execute (@sql)
        print @sql
      end
      fetch next from @c into @table_name, @IS_CLUSTERED
    end";

$commandObjectCompression = new-object system.data.sqlclient.sqlcommand($cmdObjectCompression, $targetConn);
$commandObjectCompressionResult = $commandObjectCompression.ExecuteNonQuery();

write-host 'Compression for database objects enabled!'





write-host 'Transferring data...'

$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.Connection = $sourceConn
$sqlCmd.CommandText = "
SELECT
	a3.name AS [schemaname],
	a2.name AS [tablename],
	a1.rows as row_count
FROM
	(SELECT 
		ps.object_id,
		SUM (
			CASE
				WHEN (ps.index_id < 2) THEN row_count
				ELSE 0
			END
			) AS [rows]
	FROM sys.dm_db_partition_stats ps
	GROUP BY ps.object_id) AS a1
INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id ) 
INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
WHERE
	a2.type <> N'S' and a2.type <> N'IT'
	AND a1.rows > 0
ORDER BY row_count DESC";

$Tables = @();
$reader = $sqlCmd.ExecuteReader()
while ($reader.Read()) {
    $Tables += $reader["tablename"]
}
$reader.Close()

$countTables = $Tables.Count;
$numberTable = 1;

foreach ($table in $Tables) {

    $numberTable = $numberTable + 1;
    Write-Host "$numberTable / $countTables"

    if($Tables.Contains($table) -eq $false)
    {
        continue;
    }

    $dataTransfer = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Transfer -ArgumentList $SourceDB
    $dataTransfer.DestinationDatabase = $TargetDatabase
    $dataTransfer.DestinationServer = $TargetSQLInstance
    $dataTransfer.CopyData = $true
    $dataTransfer.CopySchema = $false
    $dataTransfer.CopyAllObjects = $false
    $dataTransfer.BatchSize = 10000
    $itemTableFilter = $dataTransfer.ObjectList.Add($sourceDB.Tables[$table]);
    $dataTransferResult = $dataTransfer.TransferData()
}

write-host 'Data transferred!'



write-host 'Closing connections...'

$sourceConn.Close()
$targetConn.Close()

write-host 'Connections closed!'
