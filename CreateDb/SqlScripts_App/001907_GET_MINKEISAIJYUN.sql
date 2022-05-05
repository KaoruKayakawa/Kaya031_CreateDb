USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GET_MINKEISAIJYUN]') AND type in (N'FN'))
DROP FUNCTION [dbo].[GET_MINKEISAIJYUN]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- ����			: GET_MINKEISAIJYUN
-- �@�\			: CATSHN_INSERT_SETTING�ɂ���L�J�eM�J�e�ƈ�v���Ȃ�APP_CATSHN_MST���R�[�h���̍ŏ��l�擾
-- ������		: @paramSCD	INT ���i�ԍ�
-- �߂�l		: INT
-- �쐬��		: 2021/05/05  �쐬�� : �V�X�e�����@�ɓ�
-- ================================================

CREATE FUNCTION [dbo].[GET_MINKEISAIJYUN]
(
	@paramHTCD int,
	@paramSCD int
)

RETURNS int
AS
BEGIN

	DECLARE @minkeisaijyun int

	SELECT @minkeisaijyun = MIN(ACSM_APPKEISAIJYUN) FROM APP_CATSHN_M WITH(NOLOCK)
	LEFT JOIN CATSHN_INSERT_SETTING WITH(NOLOCK)
	ON ACSM_LCATCD = LCAT and ACSM_MCATCD = MCAT
	where LCAT IS NULL and ACSM_SCD = @paramSCD AND ACSM_HTCD = @paramHTCD

	RETURN ISNULL(@minkeisaijyun,1)

END
GO
