WITH cols AS (
  SELECT c.table_schema s, c.table_name t, c.column_name col, c.ordinal_position pos,
         CASE WHEN c.domain_name IS NOT NULL THEN c.domain_name WHEN c.data_type='USER-DEFINED' THEN c.udt_name ELSE c.data_type END typ,
         (c.is_nullable='NO') obligatoire
  FROM information_schema.columns c
  JOIN information_schema.tables tb ON tb.table_schema=c.table_schema AND tb.table_name=c.table_name AND tb.table_type='BASE TABLE'
  WHERE c.table_schema IN ('referentiel','portfolio')),
pk AS (SELECT kcu.table_schema s, kcu.table_name t, kcu.column_name col FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu USING (constraint_schema, constraint_name) WHERE tc.constraint_type='PRIMARY KEY'),
fk AS (SELECT con.conname, cl.relname t, ns.nspname s, a.attname col, clf.relname tf, af.attname colf
  FROM pg_constraint con JOIN pg_class cl ON cl.oid=con.conrelid JOIN pg_namespace ns ON ns.oid=cl.relnamespace
  JOIN pg_class clf ON clf.oid=con.confrelid
  CROSS JOIN LATERAL unnest(con.conkey, con.confkey) AS k(a1,a2)
  JOIN pg_attribute a ON a.attrelid=con.conrelid AND a.attnum=k.a1
  JOIN pg_attribute af ON af.attrelid=con.confrelid AND af.attnum=k.a2
  WHERE con.contype='f' AND ns.nspname IN ('referentiel','portfolio')),
chk AS (SELECT cl.relname t, count(*) n FROM pg_constraint con JOIN pg_class cl ON cl.oid=con.conrelid JOIN pg_namespace ns ON ns.oid=cl.relnamespace WHERE con.contype='c' AND ns.nspname IN ('referentiel','portfolio') GROUP BY 1)
SELECT json_build_object(
 'tables', (SELECT json_agg(json_build_object('s',x.s,'t',x.t,'checks',COALESCE((SELECT n FROM chk WHERE chk.t=x.t),0),'cols',
     (SELECT json_agg(json_build_object('c',col,'typ',typ,'nn',obligatoire,'pk',EXISTS(SELECT 1 FROM pk WHERE pk.s=cols.s AND pk.t=cols.t AND pk.col=cols.col),
        'fk',(SELECT tf FROM fk WHERE fk.s=cols.s AND fk.t=cols.t AND fk.col=cols.col LIMIT 1)) ORDER BY pos) FROM cols WHERE cols.s=x.s AND cols.t=x.t)))
   FROM (SELECT DISTINCT s,t FROM cols) x),
 'fks', (SELECT json_agg(json_build_object('n',conname,'t',t,'c',col,'tf',tf,'cf',colf)) FROM fk),
 'views', (SELECT json_agg(table_schema||'.'||table_name) FROM information_schema.views WHERE table_schema IN ('referentiel','portfolio')),
 'triggers', (SELECT json_agg(DISTINCT trigger_name||' ON '||event_object_table) FROM information_schema.triggers WHERE trigger_schema='portfolio'),
 'nrows', (SELECT json_object_agg(relname, n_live_tup) FROM pg_stat_user_tables WHERE schemaname IN ('referentiel','portfolio'))
);
