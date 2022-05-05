USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CONVERT_HTCD]') AND type in (N'FN'))
DROP FUNCTION [dbo].[CONVERT_HTCD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CONVERT_HTCD]
(
	@paramKAICD	int,
	@paramTENCD int
)
RETURNS varchar(30)
AS
BEGIN

	RETURN LTRIM(CAST(@paramKAICD * 10000 + @paramTENCD AS varchar(30)))

END
GO
