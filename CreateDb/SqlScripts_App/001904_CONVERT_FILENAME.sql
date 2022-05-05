USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CONVERT_FILENAME]') AND type in (N'FN'))
DROP FUNCTION [dbo].[CONVERT_FILENAME]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- ����			: GET_HTCD
-- �@�\			: �̎ГX�܃R�[�h�擾
-- ������		: @paramKAIINCD	INT ����l�ԍ�
-- �߂�l		: INT
-- �쐬��		: 2016/05/12  �쐬�� : MSYS T.Shibata
-- ================================================
CREATE FUNCTION [dbo].[CONVERT_FILENAME]
(
	@paramFileName	varchar(30),
	@paramSCD bigint
)
RETURNS varchar(30)
AS
BEGIN

	DECLARE @FILENAME varchar(30)

	IF @paramFileName IS NULL or @paramFileName = '0'
		BEGIN
			SET @FILENAME =  STR(@paramSCD) + '.gif'
		END
	ELSE
		BEGIN
			SET @FILENAME =  @paramFileName
		END

	RETURN LTRIM(@FILENAME)

END
GO
