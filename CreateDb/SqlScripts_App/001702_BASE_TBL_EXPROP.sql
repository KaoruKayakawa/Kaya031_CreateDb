USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BASE_TBL_EXPROP]') AND type in (N'V'))
DROP VIEW [dbo].[BASE_TBL_EXPROP]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[BASE_TBL_EXPROP]
AS
	SELECT a.*, b.name AS tbl_name
	FROM #{-BASE_DB-}#.sys.extended_properties a
	INNER JOIN #{-BASE_DB-}#.sys.tables b
	ON a.major_id = b.object_id
	WHERE a.class= 1
GO
