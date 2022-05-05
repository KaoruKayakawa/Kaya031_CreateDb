USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CONVERT_URIZEIKBN]') AND type in (N'FN'))
DROP FUNCTION [dbo].[CONVERT_URIZEIKBN]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CONVERT_URIZEIKBN]
(
	@paramUrizeiKbn	tinyint
)
RETURNS tinyint
AS
BEGIN

	DECLARE @URIZEIKBN tinyint

	IF @paramUrizeiKbn = 1
		BEGIN
			SET @URIZEIKBN = 0
		END
	ELSE IF @paramUrizeiKbn = 2
		BEGIN
			SET @URIZEIKBN = 1
		END
	ELSE
		BEGIN
			SET @URIZEIKBN = 9
		END

	RETURN @URIZEIKBN

END
GO
