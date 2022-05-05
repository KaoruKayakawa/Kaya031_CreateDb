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
-- 名称			: GET_MINKEISAIJYUN
-- 機能			: CATSHN_INSERT_SETTINGにあるLカテMカテと一致しないAPP_CATSHN_MSTレコード内の最小値取得
-- 引き数		: @paramSCD	INT 商品番号
-- 戻り値		: INT
-- 作成日		: 2021/05/05  作成者 : システム部　伊藤
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
