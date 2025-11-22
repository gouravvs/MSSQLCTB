/*
Note : 
1. For DBA prespective sqlserver logins is best at gives highest level of access possible on the 
managed Cloud SQL server , especially things like Agent, Audits , msdb related work etc..
2. For Development prespective prefer creating different users depending on usage as it can have 
db_owner access so you can create objects and all on the application database 

*/
USE [master]
GO
CREATE LOGIN [dev-test-stand-user] WITH PASSWORD=N'#########', DEFAULT_DATABASE=[master], 
CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
-- Granting server role (below is the highest access that can be granted by sqlsevrer user on CLoud SQL managed instances  )
ALTER SERVER ROLE [CustomerDbRootRole] ADD MEMBER [dev-test-stand-user]
GO
-- Granting access on database level 

USE [GB]--  your database name 
GO
CREATE USER [dev-test-stand-user] FOR LOGIN [dev-test-stand-user]
GO
USE [GB]
GO
ALTER ROLE [db_owner] ADD MEMBER [dev-test-stand-user]
GO
