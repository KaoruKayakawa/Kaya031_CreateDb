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
-- 名称			: CONVERT_KEISAIFLG
-- 機能			: 掲載フラグを変更
-- 引き数		: @@paramKeisaiFlg	tinyint 掲載フラグ
-- 戻り値		: tinyint
-- 作成日		: 2021/03/04  作成者 : 伊藤
-- ================================================

CREATE FUNCTION [dbo].[CONVERT_KEISAIFLG]
(
	@paramKeisaiFlg	tinyint
)
RETURNS tinyint
AS
BEGIN

	DECLARE @KEISAIFLG tinyint

	--デフォルトはCSVの値(0、1以外はそのまま登録する)
	SET @KEISAIFLG = @paramKeisaiFlg

	IF @paramKeisaiFlg = 0 SET @KEISAIFLG = 1
	IF @paramKeisaiFlg = 1 SET @KEISAIFLG = 0

	RETURN @KEISAIFLG

END
GO
