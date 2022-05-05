USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CONVERT_KEISAIFLG]') AND type in (N'FN'))
DROP FUNCTION [dbo].[CONVERT_KEISAIFLG]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- ����			: CONVERT_KEISAIFLG
-- �@�\			: �f�ڃt���O��ύX
-- ������		: @@paramKeisaiFlg	tinyint �f�ڃt���O
-- �߂�l		: tinyint
-- �쐬��		: 2021/03/04  �쐬�� : �ɓ�
-- ================================================

CREATE FUNCTION [dbo].[CONVERT_KEISAIFLG]
(
	@paramKeisaiFlg	tinyint
)
RETURNS tinyint
AS
BEGIN

	DECLARE @KEISAIFLG tinyint

	--�f�t�H���g��CSV�̒l(0�A1�ȊO�͂��̂܂ܓo�^����)
	SET @KEISAIFLG = @paramKeisaiFlg

	IF @paramKeisaiFlg = 0 SET @KEISAIFLG = 1
	IF @paramKeisaiFlg = 1 SET @KEISAIFLG = 0

	RETURN @KEISAIFLG

END
GO
