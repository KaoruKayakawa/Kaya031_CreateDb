USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GET_TYUMON_KNR_F_INFO_ALLPERIOD]') AND type in (N'IF'))
DROP FUNCTION [dbo].[GET_TYUMON_KNR_F_INFO_ALLPERIOD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ver.2021-09-17-1210 (統一化)
-- =============================================
-- 名称			:GET_TYUMON_KNR_F_INFO_ALLPERIOD
-- 機能			:有効な注文総量管理テーブル（全店舗対応）全期間取得
-- 引き数		: @paramHTCD	int			個店の販社店舗コード
-- 戻り値		: table
-- 作成日		: 2016/06/11  作成者 : MSYS M.Morishita
-- 修正日		: 2022/06/17　修正者 : 茅川　[TKF_KIKAKUCD]・[TKF_KIKAKUKBN] 追加
-- =============================================
CREATE FUNCTION [dbo].[GET_TYUMON_KNR_F_INFO_ALLPERIOD]
(	
	@paramHTCD		int		--個店の販社店舗コード
)
RETURNS TABLE 
AS
RETURN 
(
	/*注文総量管理情報取得(有効な注文総量のみ取得）*/
    select
		@paramHTCD AS HTCD,
		T1.TKF_HTCD,
		T1.TKF_KIKAKUCD,
		T1.TKF_KIKAKUKBN,
		T1.TKF_SCD,
		T1.TKF_STR,
		T1.TKF_END,
		T1.TKF_SOURYO,
		T1.TKF_NOWSURYO,
		T1.TKF_SESSIONID
    from 
        (
            select 
				/*
				row_number() over(partition by TKF_SCD, TKF_STR, TKF_END order by TKF_HTCD DESC , TKF_SCD , TKF_STR , TKF_INYMD) as RN ,
				*/
				row_number() over(partition by TKF_SCD, TKF_KIKAKUCD order by TKF_HTCD DESC) as RN ,

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
            where (TKF_HTCD = @paramHTCD or TKF_HTCD= (SELECT TOP 1 ASTM_SETVALUE FROM APP_SETTING_M WITH(NOLOCK) WHERE ASTM_SETKBN = 'AllHtcd'))
        ) As T1
    where  T1.RN  =  1
)

GO

