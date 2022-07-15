USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GET_SHOHIN_M_INFO_PERIOD]') AND type in (N'IF'))
DROP FUNCTION [dbo].[GET_SHOHIN_M_INFO_PERIOD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 名称			:GET_SHOHIN_M_INFO_PERIOD
-- 機能			:有効な受注商品マスタ（全店舗対応）取得
-- 引き数		: @paramHTCD	int			個店の販社店舗コード
--				  @paramBinYMD	datetime	便受注日
--				  @paramHAIYMD	datetime    配達日
-- 戻り値		: table
-- 作成日		: 2016/05/21  作成者 : MSYS M.Morishita
-- 修正日		: 2021/03/02　作成者 : 伊藤　掲載フラグ3対応追加
-- 修正日		: 2021/07/20　修正者 : 伊藤　#DBnow対応#
-- 修正日		: 2022/06/17　修正者 : 茅川　[SHM_BURUICD] 追加
-- =============================================
CREATE FUNCTION [dbo].[GET_SHOHIN_M_INFO_PERIOD]
(	
	@paramHTCD		int,		--個店の販社店舗コード
	@paramBinYMD	datetime,	--便受注日
	@paramHAIYMD	datetime    --配達日
)
RETURNS TABLE 
AS
RETURN 
(
	--/*受注商品マスタ情報取得(有効な受注期間及び掲載フラグのみ取得）*/
	select
	    @paramHTCD AS SHM_HTCD,
		T1.SHM_SCD,
		T1.SHM_JANCD,
		T1.SHM_BUMONCD,
		T1.SHM_BURUICD,
		T1.SHM_SHONAME,
		T1.SHM_MAKNAME,
		T1.SHM_KIKNAME,
		T1.SHM_SURYOSEIGEN,
		T1.SHM_TANKA,
		T1.SHM_YOUKIKBN,
		T1.SHM_JUNOUKIKAN,
		T1.SHM_JUCHUSTR,
		T1.SHM_JUCHUEND,
		T1.SHM_HAISTR,
		T1.SHM_HAIEND,
		T1.SHM_HAITEISTR,
		T1.SHM_HAITEIEND,
		T1.SHM_KEISAIJYUN,
		T1.SHM_YOUBIKBN,
		T1.SHM_URIZEIKBN,
		T1.SHM_SFILENAME,
		T1.SHM_KEISAIFLG,
		T1.SHM_FAVBTNDFLG,
		T1.SHM_TYUKNRFLG,
		T1.SHM_SJKBN,
		T1.SHM_SEBANGO,
		T1.SHM_ZAIKO,
		T1.SHM_KEYWORD,
		T1.SHM_NEWSORTKEY,
		--2019/06/10 軽減税率TEST 山下 Upd Start
		--SHM_SIMETIME
		SHM_SIMETIME,
		SHM_TAXKBN
		--2019/06/10 軽減税率TEST 山下 Upd End
	from 
		(
			--１．全店舗/個店が混在する場合は個店優先
		select 
			row_number() over(partition by SHM_SCD order by SHM_HTCD) as RN ,
			SHM_SCD,
			SHM_JANCD,
			SHM_BUMONCD,
			SHM_BURUICD,
			SHM_SHONAME,
			SHM_MAKNAME,
			SHM_KIKNAME,
			SHM_SURYOSEIGEN,
			SHM_TANKA,
			SHM_YOUKIKBN,
			SHM_JUNOUKIKAN,
			SHM_JUCHUSTR,
			SHM_JUCHUEND,
			SHM_HAISTR,
			SHM_HAIEND,
			SHM_HAITEISTR,
			SHM_HAITEIEND,
			SHM_KEISAIJYUN,
			SHM_YOUBIKBN,
			SHM_URIZEIKBN,
			SHM_SFILENAME,
			SHM_KEISAIFLG,
			SHM_FAVBTNDFLG,
			SHM_TYUKNRFLG,
			SHM_SJKBN,
			SHM_SEBANGO,
			SHM_ZAIKO,
			SHM_KEYWORD,
			SHM_NEWSORTKEY,
			--2019/06/10 軽減税率TEST 山下 Upd Start
			--SHM_SIMETIME
			SHM_SIMETIME,
			SHM_TAXKBN
			--2019/06/10 軽減税率TEST 山下 Upd End
		from dbo.ft_SHOHIN_M (@paramHAIYMD)
		where (SHM_HTCD = @paramHTCD or SHM_HTCD = (SELECT TOP 1 ASTM_SETVALUE FROM APP_SETTING_M WITH(NOLOCK) WHERE ASTM_SETKBN = 'AllHtcd'))
		and   (@paramBinYMD between SHM_JUCHUSTR and SHM_JUCHUEND)   --受注期間条件設定
		--↓↓↓↓ 2021/3/2 掲載フラグ3対応追加 Start ↓↓↓↓
		--and   (SHM_KEISAIFLG = 0 or SHM_KEISAIFLG = 2 or SHM_KEISAIFLG is null)		--掲載フラグ条件設定
		and   (SHM_KEISAIFLG = 0 or SHM_KEISAIFLG = 2 or SHM_KEISAIFLG = 3 or SHM_KEISAIFLG is null)		--掲載フラグ条件設定
		--↑↑↑↑ 2021/3/2 掲載フラグ3対応追加 Start ↑↑↑↑
		and   ((@paramHAIYMD >= SHM_DISPPERIODSTR)
				or   (SHM_DISPPERIODSTR IS NULL))
		and   ((@paramHAIYMD <= SHM_DISPPERIODEND)
				or   (SHM_DISPPERIODEND IS NULL))
--		and   (@paramHAIYMD >= (CASE WHEN SHM_DISPPERIODSTR = NULL THEN @paramHAIYMD ELSE SHM_DISPPERIODSTR END))
--		and   (@paramHAIYMD <= (CASE WHEN SHM_DISPPERIODEND = NULL THEN @paramHAIYMD ELSE SHM_DISPPERIODEND END))
		) as T1
   where  T1.RN  =  1
)

GO
