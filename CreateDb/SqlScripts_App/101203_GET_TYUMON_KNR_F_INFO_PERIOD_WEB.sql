USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GET_TYUMON_KNR_F_INFO_PERIOD_WEB]') AND type in (N'IF'))
DROP FUNCTION [dbo].[GET_TYUMON_KNR_F_INFO_PERIOD_WEB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 名称			:GET_TYUMON_KNR_F_INFO_PERIOD_WEB
-- 機能			:有効な注文総量管理テーブル（全店舗対応）取得
-- 引き数		: @paramHTCD	int			個店の販社店舗コード
--				  @paramBinYMD	datetime	便受注日
-- 戻り値		: table
-- 作成日		: 2020/11/24  作成者 : MSYS K.Yamashita
-- 修正日		: 2022/06/17　修正者 : 茅川　[TKF_KIKAKUCD]・[TKF_KIKAKUKBN] 追加
-- =============================================
CREATE FUNCTION [dbo].[GET_TYUMON_KNR_F_INFO_PERIOD_WEB]
(	
	@paramHTCD		int,		--個店の販社店舗コード
	@paramBinYMD	datetime	--便受注日
)
RETURNS TABLE 
AS
RETURN 
(
	/*注文総量管理情報取得(有効な注文総量のみ取得）*/
    select 
		@paramHTCD AS HTCD,
		TKF_HTCD,
		TKF_KIKAKUCD,
		TKF_KIKAKUKBN,
		TKF_SCD,
		TKF_STR,
		TKF_END,
		TKF_SOURYO,
		TKF_NOWSURYO,
		TKF_SESSIONID
    from TYUMON_KNR_F WITH (NOLOCK)
    where TKF_HTCD = @paramHTCD
	and @paramBinYMD >= TKF_STR
)

GO
