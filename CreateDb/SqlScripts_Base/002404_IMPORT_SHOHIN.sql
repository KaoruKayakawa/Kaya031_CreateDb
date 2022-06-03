USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IMPORT_SHOHIN]') AND type in (N'P'))
DROP PROCEDURE [dbo].[IMPORT_SHOHIN]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: IMPORT_SHOHIN
-- 機能			: テーブル SHOHIN_MST_now に CSV データを取り込む。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/05/04  作成者 : 茅川
-- 変更			: 2022/03/31  茅川
--				: 2022/04/15  茅川
--				: 2022/06/03  茅川
-- ====================================================
CREATE PROCEDURE [dbo].[IMPORT_SHOHIN]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_IMPORT_SHOHIN_1;
		ELSE 
			BEGIN TRANSACTION;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH

	BEGIN TRY
		DECLARE @NowDt datetime = GETDATE();
		DECLARE @Tanto varchar(100) = 'sqlserv_proc_IMPORT_SHOHIN';

-- [会社コード、店舗コード、商品コード、適用日] で予約削除
		WITH
			t1 AS (
				SELECT CSH_KAICD, CSH_TENCD, CSH_SCD, CSH_TEKIYOYMD, CSH_SHONAME, CSH_IMPORTFILE
				FROM #wt_IMPORT_SHOHIN_1
				WHERE CSH_YDELKBN = 1
			),
			t2 AS (
				SELECT SSHM_KCD, SSHM_HTCD, SSHM_SCD, SSHM_TEKIYOYMD
				FROM SHOHIN_MST_now
				WHERE SSHM_DELFG <> 1
			)
		SELECT t1.CSH_KAICD, t1.CSH_TENCD, t1.CSH_SCD, t1.CSH_TEKIYOYMD, t1.CSH_SHONAME, t1.CSH_IMPORTFILE, t2.SSHM_KCD AS CSH_KAICD_2
		INTO #wt_IMPORT_SHOHIN_2
		FROM t1
		LEFT OUTER JOIN t2
		ON t1.CSH_KAICD = t2.SSHM_KCD
			AND t1.CSH_TENCD = t2.SSHM_HTCD
			AND t1.CSH_SCD = t2.SSHM_SCD
			AND t1.CSH_TEKIYOYMD = t2.SSHM_TEKIYOYMD;

  -- 削除対象レコードが存在しない削除設定を取得
		SELECT CSH_KAICD, CSH_TENCD, CSH_SCD, CSH_TEKIYOYMD, CSH_SHONAME,
			RIGHT(CSH_IMPORTFILE, LEN(CSH_IMPORTFILE) - PATINDEX('%|%', CSH_IMPORTFILE)) AS CSV_LINENO
		FROM #wt_IMPORT_SHOHIN_2
		WHERE CSH_KAICD_2 IS NULL;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM SHOHIN_MST_now
				WHERE SSHM_DELFG <> 1
			)
		SELECT t1.*
		INTO #wt_IMPORT_SHOHIN_3
		FROM t1
		INNER JOIN #wt_IMPORT_SHOHIN_2 t2
		ON t1.SSHM_KCD = t2.CSH_KAICD
			AND t1.SSHM_HTCD = t2.CSH_TENCD
			AND t1.SSHM_SCD = t2.CSH_SCD
			AND t1.SSHM_TEKIYOYMD = t2.CSH_TEKIYOYMD;

  -- 削除対象レコードの [削除フラグ] を設定
		UPDATE #wt_IMPORT_SHOHIN_3
		SET
			SSHM_DELFG = 1,
			SSHM_KOSINYMD = @NowDt,
			SSHM_KOSINTANTO = @Tanto;
			
  -- ＤＢレコードを更新
		INSERT INTO SHOHIN_MST_now
		SELECT *
		FROM #wt_IMPORT_SHOHIN_3;
		
-- [会社コード、店舗コード、商品コード] で予約削除（※ [適用日] 以降）
		WITH
			t1 AS (
				SELECT CSH_KAICD, CSH_TENCD, CSH_SCD, CSH_TEKIYOYMD, CSH_SHONAME, CSH_IMPORTFILE
				FROM #wt_IMPORT_SHOHIN_1
				WHERE CSH_YDELKBN = 2
			),
			t2 AS (
				SELECT SSHM_KCD, SSHM_HTCD, SSHM_SCD, SSHM_TEKIYOYMD
				FROM SHOHIN_MST_now
				WHERE SSHM_DELFG <> 1
			),
			t3 AS (
				SELECT DISTINCT t1.CSH_KAICD, t1.CSH_TENCD, t1.CSH_SCD, t1.CSH_TEKIYOYMD
				FROM t1
				INNER JOIN t2
				ON t1.CSH_KAICD = t2.SSHM_KCD
					AND t1.CSH_TENCD = t2.SSHM_HTCD
					AND t1.CSH_SCD = t2.SSHM_SCD
					AND t1.CSH_TEKIYOYMD <= t2.SSHM_TEKIYOYMD
			)
		SELECT t1.CSH_KAICD, t1.CSH_TENCD, t1.CSH_SCD, t1.CSH_TEKIYOYMD, t1.CSH_SHONAME, t1.CSH_IMPORTFILE, t3.CSH_KAICD AS CSH_KAICD_2
		INTO #wt_IMPORT_SHOHIN_4
		FROM t1
		LEFT OUTER JOIN t3
		ON t1.CSH_KAICD = t3.CSH_KAICD
			AND t1.CSH_TENCD = t3.CSH_TENCD
			AND t1.CSH_SCD = t3.CSH_SCD
			AND t1.CSH_TEKIYOYMD = t3.CSH_TEKIYOYMD;
			
  -- 削除対象レコードが存在しない削除設定を取得
		SELECT CSH_KAICD, CSH_TENCD, CSH_SCD, CSH_TEKIYOYMD, CSH_SHONAME,
			RIGHT(CSH_IMPORTFILE, LEN(CSH_IMPORTFILE) - PATINDEX('%|%', CSH_IMPORTFILE)) AS CSV_LINENO
		FROM #wt_IMPORT_SHOHIN_4
		WHERE CSH_KAICD_2 IS NULL;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM SHOHIN_MST_now
				WHERE SSHM_DELFG <> 1
			),
			t2 AS (
				SELECT CSH_KAICD, CSH_TENCD, CSH_SCD, MIN(CSH_TEKIYOYMD) AS CSH_TEKIYOYMD
				FROM #wt_IMPORT_SHOHIN_4
				WHERE CSH_KAICD_2 IS NOT NULL
				GROUP BY CSH_KAICD, CSH_TENCD, CSH_SCD
			)
		SELECT t1.*
		INTO #wt_IMPORT_SHOHIN_5
		FROM t1
		INNER JOIN t2
		ON t1.SSHM_KCD = t2.CSH_KAICD
			AND t1.SSHM_HTCD = t2.CSH_TENCD
			AND t1.SSHM_SCD = t2.CSH_SCD
			AND t1.SSHM_TEKIYOYMD >= t2.CSH_TEKIYOYMD;
			
  -- 削除対象レコードの [削除フラグ] を設定
		UPDATE #wt_IMPORT_SHOHIN_5
		SET
			SSHM_DELFG = 1,
			SSHM_KOSINYMD = @NowDt,
			SSHM_KOSINTANTO = @Tanto;
			
  -- ＤＢレコードを更新
		INSERT INTO SHOHIN_MST_now
		SELECT *
		FROM #wt_IMPORT_SHOHIN_5;
				
-- [会社コード、店舗コード、商品コード] でマスタ削除（※ [適用日] 時点）
		WITH
			t1 AS (
				SELECT CSH_KAICD, CSH_TENCD, CSH_SCD, CSH_TEKIYOYMD, CSH_SHONAME, CSH_IMPORTFILE
				FROM #wt_IMPORT_SHOHIN_1
				WHERE CSH_MDELKBN = 1
			)
		SELECT t1.CSH_KAICD, t1.CSH_TENCD, t1.CSH_SCD, t1.CSH_TEKIYOYMD, t1.CSH_SHONAME, t1.CSH_IMPORTFILE, t2.SSHM_TEKIYOYMD
		INTO #wt_IMPORT_SHOHIN_101
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CSH_KAICD = t2.SSHM_KCD
			AND t1.CSH_TENCD = t2.SSHM_HTCD
			AND t1.CSH_SCD = t2.SSHM_SCD
			AND t1.CSH_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CSH_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;

  -- 削除対象レコードが存在しない削除設定を取得
		SELECT CSH_KAICD, CSH_TENCD, CSH_SCD, CSH_TEKIYOYMD, CSH_SHONAME,
			RIGHT(CSH_IMPORTFILE, LEN(CSH_IMPORTFILE) - PATINDEX('%|%', CSH_IMPORTFILE)) AS CSV_LINENO
		FROM #wt_IMPORT_SHOHIN_101
		WHERE SSHM_TEKIYOYMD IS NULL;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM SHOHIN_MST_now
				WHERE SSHM_DELFG = 0
			)
		SELECT t1.*, t2.CSH_TEKIYOYMD
		INTO #wt_IMPORT_SHOHIN_102
		FROM t1
		INNER JOIN #wt_IMPORT_SHOHIN_101 t2
		ON t1.SSHM_KCD = t2.CSH_KAICD
			AND t1.SSHM_HTCD = t2.CSH_TENCD
			AND t1.SSHM_SCD = t2.CSH_SCD
			AND t1.SSHM_TEKIYOYMD = t2.SSHM_TEKIYOYMD;

  -- 削除対象レコードを編集
		UPDATE #wt_IMPORT_SHOHIN_102
		SET
			SSHM_TEKIYOYMD = CSH_TEKIYOYMD,
			SSHM_UPDATECNT = 0,
			SSHM_DELFG = 2,
			SSHM_INYMD = @NowDt,
			SSHM_INTANTO = @Tanto,
			SSHM_KOSINYMD = @NowDt,
			SSHM_KOSINTANTO = @Tanto
		WHERE SSHM_TEKIYOYMD < CSH_TEKIYOYMD;

		UPDATE #wt_IMPORT_SHOHIN_102
		SET
			SSHM_DELFG = 2,
			SSHM_KOSINYMD = @NowDt,
			SSHM_KOSINTANTO = @Tanto
		WHERE SSHM_TEKIYOYMD = CSH_TEKIYOYMD;
			
  -- ＤＢレコードを更新
		INSERT INTO SHOHIN_MST_now
		SELECT SSHM_KCD,
			SSHM_HTCD,
			SSHM_SCD,
			SSHM_TEKIYOYMD,
			SSHM_UPDATECNT,
			SSHM_JANCD1,
			SSHM_JANCD2,
			SSHM_JANCD3,
			SSHM_JANCD4,
			SSHM_JANCD5,
			SSHM_JANINYMD1,
			SSHM_JANINYMD2,
			SSHM_JANINYMD3,
			SSHM_JANINYMD4,
			SSHM_JANINYMD5,
			SSHM_GAIHANSCD,
			SSHM_BUMONCD,
			SSHM_BURUICD,
			SSHM_SHONAME,
			SSHM_MAKNAME,
			SSHM_HINNAME,
			SSHM_KIKNAME1,
			SSHM_KIKNAME2,
			SSHM_SURYOSEIGEN,
			SSHM_STANKA,
			SSHM_STANKAHON,
			SSHM_TANKA,
			SSHM_YOUKIKBN,
			SSHM_JUNOUKIKAN,
			SSHM_JUCHUSTR,
			SSHM_JUCHUEND,
			SSHM_HAISTR,
			SSHM_HAIEND,
			SSHM_HAITEISTR,
			SSHM_HAITEIEND,
			SSHM_KEISAIPAGE,
			SSHM_KEISAIJUN,
			SSHM_YOUBIKBN,
			SSHM_TOKUSHOKBN,
			SSHM_BUNKATU,
			SSHM_TANAGON,
			SSHM_TANADAN,
			SSHM_TANANARA,
			SSHM_TANAFACE,
			SSHM_TANAADDRESS,
			SSHM_URIZEIKBN,
			SSHM_SIIREZEIKBN,
			SSHM_ZEIRITUKBN,
			SSHM_SIIRECD,
			SSHM_FSKIKAKUNO,
			SSHM_HTORIKBN,
			SSHM_PICKKBN,
			SSHM_SFILENAME,
			SSHM_KEISAIFLG,
			SSHM_FAVBTNDFLG,
			SSHM_TYUKNRFLG,
			SSHM_SJKBN,
			SSHM_SEBANGO,
			SSHM_NEWSORTKEY,
			SSHM_SIMETIME,
			SSHM_DISPCONTROLFLG,
			SSHM_COMMENTDISPFLG,
			SSHM_KISETUKBN,
			SSHM_OYASCD,
			SSHM_FUTEIKANKBN,
			SSHM_NAIYO,
			SSHM_GENZAIRYO,
			SSHM_SEIBUN,
			SSHM_KEYWORD,
			SSHM_CHIRASHIKBN,
			SSHM_JUCYUKOSINFLG,
			SSHM_JANCD6,
			SSHM_JANCD7,
			SSHM_JANCD8,
			SSHM_JANCD9,
			SSHM_SURYOSEIGEN_M,
			SSHM_SEIGYOKBN,
			SSHM_TEISHIKBN,
			SSHM_RANK,
			SSHM_MYSHNKBN,
			SSHM_TOBASHIDISPKBN,
			SSHM_NOTSEARCHKBN,
			SSHM_KENSACD,
			SSHM_100BAIKA,
			SSHM_MAXBAIKA,
			SSHM_MINBAIKA,
			SSHM_MAXGRAM,
			SSHM_MINGRAM,
			SSHM_ALLERGEN,
			SSHM_YDELKBN,
			SSHM_MDELKBN,
			SSHM_YOBI1,
			SSHM_YOBI2,
			SSHM_YOBI3,
			SSHM_YOBI4,
			SSHM_YOBI5,
			SSHM_YOBI6,
			SSHM_YOBI7,
			SSHM_YOBI8,
			SSHM_YOBI9,
			SSHM_IMPORTYMD,
			SSHM_IMPORTFILE,
			SSHM_DELFG,
			SSHM_INYMD,
			SSHM_INTANTO,
			SSHM_KOSINYMD,
			SSHM_KOSINTANTO
		FROM #wt_IMPORT_SHOHIN_102;

-- レコード登録
		-- 非掲載商品の区分を再設定
		UPDATE t1
		SET CSH_KEISAIKBN = 0
		FROM #wt_IMPORT_SHOHIN_1 t1
		INNER JOIN ft_MIKEISAI_SCD_MST(NULL) t2
		ON t1.CSH_KAICD = t2.MKS_KCD
			AND t1.CSH_TENCD = t2.MKS_HTCD
			AND t1.CSH_SCD = t2.MKS_SCD
			AND (t1.CSH_TEKIYOYMD >= t2.MKS_STR OR t2.MKS_STR IS NULL)
			AND (t1.CSH_TEKIYOYMD <= t2.MKS_END OR t2.MKS_END IS NULL);

		SELECT t1.*, t2.*
		INTO #wt_IMPORT_SHOHIN_6
		FROM #wt_IMPORT_SHOHIN_1 t1
		LEFT OUTER JOIN SHOHIN_MST_now t2
		ON t1.CSH_KAICD = t2.SSHM_KCD
			AND t1.CSH_TENCD = t2.SSHM_HTCD
			AND t1.CSH_SCD = t2.SSHM_SCD
			AND t1.CSH_TEKIYOYMD = t2.SSHM_TEKIYOYMD;

  -- レコード更新
    -- 予約・マスタ 削除レコード
		INSERT INTO SHOHIN_MST_now
		SELECT
			SSHM_KCD,
			SSHM_HTCD,
			SSHM_SCD,
			SSHM_TEKIYOYMD,
			SSHM_UPDATECNT,
			SSHM_JANCD1,
			SSHM_JANCD2,
			SSHM_JANCD3,
			SSHM_JANCD4,
			SSHM_JANCD5,
			SSHM_JANINYMD1,
			SSHM_JANINYMD2,
			SSHM_JANINYMD3,
			SSHM_JANINYMD4,
			SSHM_JANINYMD5,
			SSHM_GAIHANSCD,
			SSHM_BUMONCD,
			SSHM_BURUICD,
			SSHM_SHONAME,
			SSHM_MAKNAME,
			SSHM_HINNAME,
			SSHM_KIKNAME1,
			SSHM_KIKNAME2,
			SSHM_SURYOSEIGEN,
			SSHM_STANKA,
			SSHM_STANKAHON,
			SSHM_TANKA,
			SSHM_YOUKIKBN,
			SSHM_JUNOUKIKAN,
			SSHM_JUCHUSTR,
			SSHM_JUCHUEND,
			SSHM_HAISTR,
			SSHM_HAIEND,
			SSHM_HAITEISTR,
			SSHM_HAITEIEND,
			SSHM_KEISAIPAGE,
			SSHM_KEISAIJUN,
			SSHM_YOUBIKBN,
			SSHM_TOKUSHOKBN,
			SSHM_BUNKATU,
			SSHM_TANAGON,
			SSHM_TANADAN,
			SSHM_TANANARA,
			SSHM_TANAFACE,
			SSHM_TANAADDRESS,
			SSHM_URIZEIKBN,
			SSHM_SIIREZEIKBN,
			SSHM_ZEIRITUKBN,
			SSHM_SIIRECD,
			SSHM_FSKIKAKUNO,
			SSHM_HTORIKBN,
			SSHM_PICKKBN,
			SSHM_SFILENAME,
			SSHM_KEISAIFLG,
			SSHM_FAVBTNDFLG,
			SSHM_TYUKNRFLG,
			SSHM_SJKBN,
			SSHM_SEBANGO,
			SSHM_NEWSORTKEY,
			SSHM_SIMETIME,
			SSHM_DISPCONTROLFLG,
			SSHM_COMMENTDISPFLG,
			SSHM_KISETUKBN,
			SSHM_OYASCD,
			SSHM_FUTEIKANKBN,
			SSHM_NAIYO,
			SSHM_GENZAIRYO,
			SSHM_SEIBUN,
			SSHM_KEYWORD,
			SSHM_CHIRASHIKBN,
			SSHM_JUCYUKOSINFLG,
			SSHM_JANCD6,
			SSHM_JANCD7,
			SSHM_JANCD8,
			SSHM_JANCD9,
			SSHM_SURYOSEIGEN,
			SSHM_SEIGYOKBN,
			SSHM_TEISHIKBN,
			SSHM_RANK,
			SSHM_MYSHNKBN,
			SSHM_TOBASHIDISPKBN,
			SSHM_NOTSEARCHKBN,
			SSHM_KENSACD,
			SSHM_100BAIKA,
			SSHM_MAXBAIKA,
			SSHM_MINBAIKA,
			SSHM_MAXGRAM,
			SSHM_MINGRAM,
			SSHM_ALLERGEN,
			CSH_YDELKBN,
			CSH_MDELKBN,
			SSHM_YOBI1,
			SSHM_YOBI2,
			SSHM_YOBI3,
			SSHM_YOBI4,
			SSHM_YOBI5,
			SSHM_YOBI6,
			SSHM_YOBI7,
			SSHM_YOBI8,
			SSHM_YOBI9,
			CSH_IMPORTYMD,
			CSH_IMPORTFILE,
			SSHM_DELFG,
			SSHM_INYMD,
			SSHM_INTANTO,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SHOHIN_6
		WHERE SSHM_KCD IS NOT NULL
			AND CSH_YDELKBN + CSH_MDELKBN > 0;
			
    -- 通常レコード
		INSERT INTO SHOHIN_MST_now
		SELECT
			SSHM_KCD,
			SSHM_HTCD,
			SSHM_SCD,
			SSHM_TEKIYOYMD,
			SSHM_UPDATECNT,
			CSH_JANCD1,
			CSH_JANCD2,
			CSH_JANCD3,
			CSH_JANCD4,
			CSH_JANCD5,
			SSHM_JANINYMD1,
			SSHM_JANINYMD2,
			SSHM_JANINYMD3,
			SSHM_JANINYMD4,
			SSHM_JANINYMD5,
			CSH_GAIHANSCD,
			CSH_BUMONCD,
			CSH_BURUICD,
			REPLACE(CSH_SHONAME,'　',' '),
			SSHM_MAKNAME,
			SSHM_HINNAME,
			SSHM_KIKNAME1,
			SSHM_KIKNAME2,
			0, -- ISNULL(CSH_SURYOSEIGEN, 0),		-- [SSHM_SURYOSEIGEN_M] を使用する（2022-03-31）
			ISNULL(CSH_STANKA, 0),
			SSHM_STANKAHON,
			CSH_TANKA,
			CSH_YOUKIKBN,
			ISNULL(CSH_JUNOUKIKAN, 0),
			CSH_JUCHUSTR,
			CSH_JUCHUEND,
			CSH_HAISTR,
			CSH_HAIEND,
			SSHM_HAITEISTR,
			SSHM_HAITEIEND,
			SSHM_KEISAIPAGE,
			CSH_KEISAIJUN,
			LEFT(CSH_YOUBIKBN, 7),
			CSH_TOKUSHOKBN,
			SSHM_BUNKATU,
			CSH_TANAGON,
			ISNULL(CSH_TANADAN, 0),
			ISNULL(CSH_TANANARA, 0),
			ISNULL(CSH_TANAFACE, 0),
			FORMAT(CSH_TANAGON, '0000') + FORMAT(ISNULL(CSH_TANADAN, 0), '0') + FORMAT(ISNULL(CSH_TANANARA, 0), '00') + FORMAT(ISNULL(CSH_TANAFACE, 0), '0'),
			CSH_URIZEIKBN,
			SSHM_SIIREZEIKBN,
			CSH_ZEIRITUKBN,
			SSHM_SIIRECD,
			SSHM_FSKIKAKUNO,
			SSHM_HTORIKBN,
			SSHM_PICKKBN,
			dbo.CONVERT_FILENAME(CSH_SFILENAME, CSH_SCD),
			CSH_KEISAIKBN,
			ISNULL(CSH_FAVBTNKBN, 0),
			ISNULL(CSH_TYUKNRKBN, 0),
			ISNULL(CSH_SJKBN, 0),
			CSH_SEBANGO,
			SSHM_NEWSORTKEY,
			CSH_SIMETIME,
			SSHM_DISPCONTROLFLG,
			SSHM_COMMENTDISPFLG,
			SSHM_KISETUKBN,
			CSH_OYASCD,
			CSH_FUTEIKANKBN,
			CSH_NAIYO,
			CSH_GENZAIRYO,
			CSH_SEIBUN,

			/* 更新前レコードの値を引き継ぐ　->　CSV 設定値を用いる　（2022-06-03）
			SSHM_KEYWORD,
			*/
			CSH_SEARCHWORD,

			CSH_CHIRASHIKBN,
			0,
			CSH_JANCD6,
			CSH_JANCD7,
			CSH_JANCD8,
			CSH_JANCD9,
			CSH_SURYOSEIGEN,
			CSH_SEIGYOKBN,
			CSH_TEISHIKBN,
			CSH_RANK,
			CSH_MYSHNKBN,
			CSH_TOBASHIDISPKBN,
			CSH_NOTSEARCHKBN,
			CSH_KENSACD,
			CSH_100BAIKA,
			CSH_MAXBAIKA,
			CSH_MINBAIKA,
			CSH_MAXGRAM,
			CSH_MINGRAM,
			CSH_ALLERGEN,
			CSH_YDELKBN,
			CSH_MDELKBN,
			CSH_YOBI1,
			CSH_YOBI2,
			CSH_YOBI3,
			CSH_YOBI4,
			CSH_YOBI5,
			CSH_YOBI6,
			CSH_YOBI7,
			CSH_YOBI8,
			CSH_YOBI9,
			CSH_IMPORTYMD,
			CSH_IMPORTFILE,
			0,
			SSHM_INYMD,
			SSHM_INTANTO,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SHOHIN_6
		WHERE SSHM_KCD IS NOT NULL
			AND CSH_YDELKBN = 0 AND CSH_MDELKBN = 0;

  -- レコード追加
    -- 予約・マスタ 削除レコード
		INSERT INTO SHOHIN_MST_now
		SELECT
			CSH_KAICD,
			CSH_TENCD,
			CSH_SCD,
			CSH_TEKIYOYMD,
			0,
			CSH_JANCD1,
			CSH_JANCD2,
			CSH_JANCD3,
			CSH_JANCD4,
			CSH_JANCD5,
			GETDATE(),
			NULL,
			NULL,
			NULL,
			NULL,
			CSH_GAIHANSCD,
			CSH_BUMONCD,
			CSH_BURUICD,
			REPLACE(CSH_SHONAME,'　',' '),
			NULL,
			NULL,
			NULL,
			NULL,
			0, -- ISNULL(CSH_SURYOSEIGEN, 0),		-- [SSHM_SURYOSEIGEN_M] を使用する（2022-03-31）
			ISNULL(CSH_STANKA, 0),
			0,
			CSH_TANKA,
			CSH_YOUKIKBN,
			ISNULL(CSH_JUNOUKIKAN, 0),
			CSH_JUCHUSTR,
			CSH_JUCHUEND,
			CSH_HAISTR,
			CSH_HAIEND,
			CAST('1753-1-1' AS datetime),
			CAST('1753-1-1' AS datetime),
			0,
			CSH_KEISAIJUN,
			LEFT(CSH_YOUBIKBN, 7),
			CSH_TOKUSHOKBN,
			0,
			CSH_TANAGON,
			ISNULL(CSH_TANADAN, 0),
			ISNULL(CSH_TANANARA, 0),
			ISNULL(CSH_TANAFACE, 0),
			FORMAT(CSH_TANAGON, '0000') + FORMAT(ISNULL(CSH_TANADAN, 0), '0') + FORMAT(ISNULL(CSH_TANANARA, 0), '00') + FORMAT(ISNULL(CSH_TANAFACE, 0), '0'),
			CSH_URIZEIKBN,
			0,
			CSH_ZEIRITUKBN,
			0,
			0,
			0,
			0,
			dbo.CONVERT_FILENAME(CSH_SFILENAME, CSH_SCD),
			CSH_KEISAIKBN,
			ISNULL(CSH_FAVBTNKBN, 0),
			ISNULL(CSH_TYUKNRKBN, 0),
			ISNULL(CSH_SJKBN, 0),
			CSH_SEBANGO,
			0,
			CSH_SIMETIME,
			0,
			0,
			NULL,
			CSH_OYASCD,
			CSH_FUTEIKANKBN,
			CSH_NAIYO,
			CSH_GENZAIRYO,
			CSH_SEIBUN,
			CSH_SEARCHWORD,
			CSH_CHIRASHIKBN,
			0,
			CSH_JANCD6,
			CSH_JANCD7,
			CSH_JANCD8,
			CSH_JANCD9,
			CSH_SURYOSEIGEN,
			CSH_SEIGYOKBN,
			CSH_TEISHIKBN,
			CSH_RANK,
			CSH_MYSHNKBN,
			CSH_TOBASHIDISPKBN,
			CSH_NOTSEARCHKBN,
			CSH_KENSACD,
			CSH_100BAIKA,
			CSH_MAXBAIKA,
			CSH_MINBAIKA,
			CSH_MAXGRAM,
			CSH_MINGRAM,
			CSH_ALLERGEN,
			CSH_YDELKBN,
			CSH_MDELKBN,
			CSH_YOBI1,
			CSH_YOBI2,
			CSH_YOBI3,
			CSH_YOBI4,
			CSH_YOBI5,
			CSH_YOBI6,
			CSH_YOBI7,
			CSH_YOBI8,
			CSH_YOBI9,
			CSH_IMPORTYMD,
			CSH_IMPORTFILE,
			1,
			@NowDt,
			@Tanto,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SHOHIN_6
		WHERE SSHM_KCD IS NULL
			AND CSH_YDELKBN + CSH_MDELKBN > 0;
			
    -- 通常レコード
		INSERT INTO SHOHIN_MST_now
		SELECT
			CSH_KAICD,
			CSH_TENCD,
			CSH_SCD,
			CSH_TEKIYOYMD,
			0,
			CSH_JANCD1,
			CSH_JANCD2,
			CSH_JANCD3,
			CSH_JANCD4,
			CSH_JANCD5,
			GETDATE(),
			NULL,
			NULL,
			NULL,
			NULL,
			CSH_GAIHANSCD,
			CSH_BUMONCD,
			CSH_BURUICD,
			REPLACE(CSH_SHONAME,'　',' '),
			NULL,
			NULL,
			NULL,
			NULL,
			0, -- ISNULL(CSH_SURYOSEIGEN, 0),		-- [SSHM_SURYOSEIGEN_M] を使用する（2022-03-31）
			ISNULL(CSH_STANKA, 0),
			0,
			CSH_TANKA,
			CSH_YOUKIKBN,
			ISNULL(CSH_JUNOUKIKAN, 0),
			CSH_JUCHUSTR,
			CSH_JUCHUEND,
			CSH_HAISTR,
			CSH_HAIEND,
			CAST('1753-1-1' AS datetime),
			CAST('1753-1-1' AS datetime),
			0,
			CSH_KEISAIJUN,
			LEFT(CSH_YOUBIKBN, 7),
			CSH_TOKUSHOKBN,
			0,
			CSH_TANAGON,
			ISNULL(CSH_TANADAN, 0),
			ISNULL(CSH_TANANARA, 0),
			ISNULL(CSH_TANAFACE, 0),
			FORMAT(CSH_TANAGON, '0000') + FORMAT(ISNULL(CSH_TANADAN, 0), '0') + FORMAT(ISNULL(CSH_TANANARA, 0), '00') + FORMAT(ISNULL(CSH_TANAFACE, 0), '0'),
			CSH_URIZEIKBN,
			0,
			CSH_ZEIRITUKBN,
			0,
			0,
			0,
			0,
			dbo.CONVERT_FILENAME(CSH_SFILENAME, CSH_SCD),
			CSH_KEISAIKBN,
			ISNULL(CSH_FAVBTNKBN, 0),
			ISNULL(CSH_TYUKNRKBN, 0),
			ISNULL(CSH_SJKBN, 0),
			CSH_SEBANGO,
			0,
			CSH_SIMETIME,
			0,
			0,
			NULL,
			CSH_OYASCD,
			CSH_FUTEIKANKBN,
			CSH_NAIYO,
			CSH_GENZAIRYO,
			CSH_SEIBUN,
			CSH_SEARCHWORD,
			CSH_CHIRASHIKBN,
			0,
			CSH_JANCD6,
			CSH_JANCD7,
			CSH_JANCD8,
			CSH_JANCD9,
			CSH_SURYOSEIGEN,
			CSH_SEIGYOKBN,
			CSH_TEISHIKBN,
			CSH_RANK,
			CSH_MYSHNKBN,
			CSH_TOBASHIDISPKBN,
			CSH_NOTSEARCHKBN,
			CSH_KENSACD,
			CSH_100BAIKA,
			CSH_MAXBAIKA,
			CSH_MINBAIKA,
			CSH_MAXGRAM,
			CSH_MINGRAM,
			CSH_ALLERGEN,
			CSH_YDELKBN,
			CSH_MDELKBN,
			CSH_YOBI1,
			CSH_YOBI2,
			CSH_YOBI3,
			CSH_YOBI4,
			CSH_YOBI5,
			CSH_YOBI6,
			CSH_YOBI7,
			CSH_YOBI8,
			CSH_YOBI9,
			CSH_IMPORTYMD,
			CSH_IMPORTFILE,
			0,
			@NowDt,
			@Tanto,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SHOHIN_6
		WHERE SSHM_KCD IS NULL
			AND CSH_YDELKBN = 0 AND CSH_MDELKBN = 0;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_IMPORT_SHOHIN_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
