USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KAKAKU_MST_now]') AND type in (N'V'))
DROP VIEW [dbo].[KAKAKU_MST_now]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[KAKAKU_MST_now]
AS
	SELECT *
	FROM #{-BASE_DB-}#.dbo.KAKAKU_MST_now
GO
