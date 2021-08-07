 with servers (host, services) as 
   (
   select 'host1','aaa,bbb,ccc' from dual
   union all
   select 'host2','ddd,eee,fff' from dual
   union all
   select 'host3','ggg,hhh,iii' from dual
   )
   select * from servers;
   
   with servers (host, services) as 
   (
   select 'host1','aaa,bbb,ccc' from dual
   union all
   select 'host2','ddd,eee,fff' from dual
   union all
   select 'host3','ggg,hhh,iii' from dual
   )
   select servers.*, extractValue(value(t),'b') service
   from servers,
   table(XMLSequence(XMLType('<a><b>' || replace(servers.services, ',', '</b><b>') || '</b></a>').extract('a/b'))) t;
