local this ={}
local cfg = require("config.cfg")
function this.checkTableHas(tableName)
	return string.format("SELECT table_name FROM information_schema.TABLES \
     WHERE TABLE_SCHEMA=\'%s\' and table_name =\'%s\';",cfg.mysqlCfg.database,tableName)
end

function this.createTable(tableName,columnNameOptions,primaryKey,secondaryKeys)
	local str = "CREATE TABLE "..tableName.." ("
	for key, value in pairs(columnNameOptions) do
		str = str..key.." "..value..","
	end
	local allPrimaryKeys = primaryKey
	if secondaryKeys then
		allPrimaryKeys = allPrimaryKeys ..",".. secondaryKeys
	end
	str = str .. string.format("PRIMARY KEY (%s))",allPrimaryKeys)
	return str
end

function this.getTableColumnNames(tableName)
	return string.format("select column_name from information_schema.COLUMNS where table_name='%s'"
	,tableName)
end

function this.addColumn(tableName,columnName,ops)
	return string.format("alter table %s add %s %s;"
	,tableName,columnName,ops)
end

--获取数据
function this.getRow(tablename, keyname, value)
	return string.format("select * from %s where %s = '%s';", tablename, keyname, value)
end

function this.getTables(tableName)
	return string.format("select * from %s;", tableName)
end

--插入数据
function this.addRow(tablename, row)
	local columns
	local values
	for k, v in pairs(row) do
		if not columns then
			columns = k
		else
			columns = columns..","..k
		end
		if not values then
			values = "'"..v.."'"
		else
			values = values..",".."'"..v.."'"
		end
	end
	return string.format("insert into %s(%s) values(%s);", tablename, columns, values)
end

--删除数据
function this.delRow(tablename, keyname, value)
	local sql = string.format("delete from %s where %s = '%s';", keyname, tostring(value))

	return sql
end

--更新数据
function this.updateRow(tablename, row, keyname, value)
	local body = {}
	for k, v in pairs(row) do
		table.insert(body, string.format("%s='%s'",k, v))
	end
	local setvalues = table.concat(body, ",")

	local sql = string.format("update %s set %s where %s ='%s';", tablename, setvalues, keyname, value)

	return sql
end


--插入数据
function this.addLogRow(tablename, row)
	local columns
	local values
	for k, v in pairs(row) do
		if not columns then
			columns = k
		else
			columns = columns..","..k
		end
		if not values then
			values = "'"..v.."'"
		else
			values = values..",".."'"..v.."'"
		end
	end
	local sql = string.format("insert into %s(%s) values(%s);", tablename, columns, values)
	return sql
end



return this
