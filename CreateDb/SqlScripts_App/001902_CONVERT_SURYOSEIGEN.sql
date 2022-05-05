USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CONVERT_SURYOSEIGEN]') AND type in (N'FN'))
DROP FUNCTION [dbo].[CONVERT_SURYOSEIGEN]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CONVERT_SURYOSEIGEN]
(
	@paramSuryoSeigen	smallint,
	@paramSeigyoKbn	smallint,
	@paramTeishiKbn	smallint
)
RETURNS smallint
AS
BEGIN

	DECLARE @SURYOSEIGEN smallint

	IF @paramTeishiKbn >= 900
		BEGIN
			SET @SURYOSEIGEN = @paramTeishiKbn
		END
	ELSE IF @paramSeigyoKbn >= 600
		BEGIN
			SET @SURYOSEIGEN = @paramSeigyoKbn
		END
	ELSE IF (@paramSuryoSeigen = 0) OR (@paramSuryoSeigen IS NULL)
		BEGIN
			SET @SURYOSEIGEN = 99
		END
	ELSE
		BEGIN
			SET @SURYOSEIGEN = @paramSuryoSeigen
		END

	RETURN @SURYOSEIGEN

END
GO
