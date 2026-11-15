#!/bin/sh
set -eu
export PGPASSWORD="$POSTGRES_PASSWORD"
psql -X -v ON_ERROR_STOP=1 -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'SQL'
\getenv senha METABASE_READER_PASSWORD
\getenv banco POSTGRES_DB
begin;
create schema if not exists gold;
select 'create role metabase_reader login'
where not exists (select from pg_roles where rolname = 'metabase_reader')
\gexec
alter role metabase_reader password :'senha' nosuperuser nocreatedb nocreaterole;
grant connect on database :"banco" to metabase_reader;
grant usage on schema gold to metabase_reader;
grant select on all tables in schema gold to metabase_reader;
alter default privileges in schema gold grant select on tables to metabase_reader;
commit;
SQL
