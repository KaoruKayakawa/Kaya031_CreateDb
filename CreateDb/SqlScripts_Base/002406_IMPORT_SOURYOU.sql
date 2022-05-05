USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IMPORT_SOURYOU]') AND type in (N'P'))
DROP PROCEDURE [dbo].[IMPORT_SOURYOU]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: IMPORT_SOURYOU
-- 機能			: テーブル TYUMON_KNR_MST_now に CSV データを取り込む。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/05/04  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[IMPORT_SOURYOU]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_IMPORT_SOURYOU_1;
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
		DECLARE @Tanto varchar(100) = 'sqlserv_proc_IMPORT_SOURYOU';

-- [会社コード、店舗コード、商品コード、適用日、開始日、終了日] で予約削除
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_TEKIYOYMD, CSO_STR, CSO_END, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_1
				WHERE CSO_YDELKBN = 1
			),
			t2 AS (
				SELECT STKF_KCD, STKF_HTCD, STKF_SCD, STKF_TEKIYOYMD, STKF_STR, STKF_END
				FROM TYUMON_KNR_MST_now
				WHERE STKF_DELFG <> 1
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_TEKIYOYMD, t1.CSO_STR, t1.CSO_END, t1.CSO_IMPORTFILE, t2.STKF_KCD AS CSO_KCD_2
		INTO #wt_IMPORT_SOURYOU_2
		FROM t1
		LEFT OUTER JOIN t2
		ON t1.CSO_KCD = t2.STKF_KCD
			AND t1.CSO_TENCD = t2.STKF_HTCD
			AND t1.CSO_SCD = t2.STKF_SCD
			AND t1.CSO_TEKIYOYMD = t2.STKF_TEKIYOYMD
			AND t1.CSO_STR = t2.STKF_STR
			AND t1.CSO_END = t2.STKF_END;

  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_TEKIYOYMD, CSO_STR, CSO_END, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_2
				WHERE CSO_KCD_2 IS NULL
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_STR, t1.CSO_END, t1.CSO_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CSO_IMPORTFILE, LEN(t1.CSO_IMPORTFILE) - PATINDEX('%|%', t1.CSO_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CSO_KCD = t2.SSHM_KCD
			AND t1.CSO_TENCD = t2.SSHM_HTCD
			AND t1.CSO_SCD = t2.SSHM_SCD
			AND t1.CSO_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CSO_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM TYUMON_KNR_MST_now
				WHERE STKF_DELFG <> 1
			)
		SELECT t1.*
		INTO #wt_IMPORT_SOURYOU_3
		FROM t1
		INNER JOIN #wt_IMPORT_SOURYOU_2 t2
		ON t1.STKF_KCD = t2.CSO_KCD
			AND t1.STKF_HTCD = t2.CSO_TENCD
			AND t1.STKF_SCD = t2.CSO_SCD
			AND t1.STKF_TEKIYOYMD = t2.CSO_TEKIYOYMD
			AND t1.STKF_STR = t2.CSO_STR
			AND t1.STKF_END = t2.CSO_END;

  -- 削除対象レコードの [削除フラグ] を設定
		UPDATE #wt_IMPORT_SOURYOU_3
		SET
			STKF_DELFG = 1,
			STKF_KOSINYMD = @NowDt,
			STKF_KOSINTANTO = @Tanto;
			
  -- ＤＢレコードを更新
		INSERT INTO TYUMON_KNR_MST_now
		SELECT *
		FROM #wt_IMPORT_SOURYOU_3;
		
-- [会社コード、店舗コード、商品コード] で予約削除（※ [適用日] 以降）
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_TEKIYOYMD, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_1
				WHERE CSO_YDELKBN = 2
			),
			t2 AS (
				SELECT STKF_KCD, STKF_HTCD, STKF_SCD, STKF_TEKIYOYMD
				FROM TYUMON_KNR_MST_now
				WHERE STKF_DELFG <> 1
			),
			t3 AS (
				SELECT DISTINCT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_TEKIYOYMD
				FROM t1
				INNER JOIN t2
				ON t1.CSO_KCD = t2.STKF_KCD
					AND t1.CSO_TENCD = t2.STKF_HTCD
					AND t1.CSO_SCD = t2.STKF_SCD
					AND t1.CSO_TEKIYOYMD <= t2.STKF_TEKIYOYMD
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_TEKIYOYMD, t1.CSO_IMPORTFILE, t3.CSO_KCD AS CSO_KCD_2
		INTO #wt_IMPORT_SOURYOU_4
		FROM t1
		LEFT OUTER JOIN t3
		ON t1.CSO_KCD = t3.CSO_KCD
			AND t1.CSO_TENCD = t3.CSO_TENCD
			AND t1.CSO_SCD = t3.CSO_SCD
			AND t1.CSO_TEKIYOYMD = t3.CSO_TEKIYOYMD;
			
  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_TEKIYOYMD, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_4
				WHERE CSO_KCD_2 IS NULL
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CSO_IMPORTFILE, LEN(t1.CSO_IMPORTFILE) - PATINDEX('%|%', t1.CSO_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CSO_KCD = t2.SSHM_KCD
			AND t1.CSO_TENCD = t2.SSHM_HTCD
			AND t1.CSO_SCD = t2.SSHM_SCD
			AND t1.CSO_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CSO_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM TYUMON_KNR_MST_now
				WHERE STKF_DELFG <> 1
			),
			t2 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, MIN(CSO_TEKIYOYMD) AS CSO_TEKIYOYMD
				FROM #wt_IMPORT_SOURYOU_4
				WHERE CSO_KCD_2 IS NOT NULL
				GROUP BY CSO_KCD, CSO_TENCD, CSO_SCD
			)
		SELECT t1.*
		INTO #wt_IMPORT_SOURYOU_5
		FROM t1
		INNER JOIN t2
		ON t1.STKF_KCD = t2.CSO_KCD
			AND t1.STKF_HTCD = t2.CSO_TENCD
			AND t1.STKF_SCD = t2.CSO_SCD
			AND t1.STKF_TEKIYOYMD >= t2.CSO_TEKIYOYMD;
			
  -- 削除対象レコードの [削除フラグ] を設定
		UPDATE #wt_IMPORT_SOURYOU_5
		SET
			STKF_DELFG = 1,
			STKF_KOSINYMD = @NowDt,
			STKF_KOSINTANTO = @Tanto;
			
  -- ＤＢレコードを更新
		INSERT INTO TYUMON_KNR_MST_now
		SELECT *
		FROM #wt_IMPORT_SOURYOU_5;
		
-- [会社コード、店舗コード、商品コード、開始日、終了日] でマスタ削除（※ [適用日] 時点）
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_STR, CSO_END, CSO_TEKIYOYMD, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_1
				WHERE CSO_MDELKBN = 1
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_STR, t1.CSO_END, t1.CSO_TEKIYOYMD, t1.CSO_IMPORTFILE, t2.STKF_TEKIYOYMD
		INTO #wt_IMPORT_SOURYOU_101
		FROM t1
		LEFT OUTER JOIN vi_TYUMON_KNR_MST t2
		ON t1.CSO_KCD = t2.STKF_KCD
			AND t1.CSO_TENCD = t2.STKF_HTCD
			AND t1.CSO_SCD = t2.STKF_SCD
			AND t1.CSO_STR = t2.STKF_STR
			AND t1.CSO_END = t2.STKF_END
			AND t1.CSO_TEKIYOYMD >= t2.STKF_TEKIYOYMD
			AND t1.CSO_TEKIYOYMD <= t2.STKF_TEKIYOYMD_END;

  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_STR, CSO_END, CSO_TEKIYOYMD, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_101
				WHERE STKF_TEKIYOYMD IS NULL
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_STR, t1.CSO_END, t1.CSO_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CSO_IMPORTFILE, LEN(t1.CSO_IMPORTFILE) - PATINDEX('%|%', t1.CSO_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CSO_KCD = t2.SSHM_KCD
			AND t1.CSO_TENCD = t2.SSHM_HTCD
			AND t1.CSO_SCD = t2.SSHM_SCD
			AND t1.CSO_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CSO_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM TYUMON_KNR_MST_now
				WHERE STKF_DELFG = 0
			)
		SELECT t1.*, t2.CSO_TEKIYOYMD
		INTO #wt_IMPORT_SOURYOU_102
		FROM t1
		INNER JOIN #wt_IMPORT_SOURYOU_101 t2
		ON t1.STKF_KCD = t2.CSO_KCD
			AND t1.STKF_HTCD = t2.CSO_TENCD
			AND t1.STKF_SCD = t2.CSO_SCD
			AND t1.STKF_STR = t2.CSO_STR
			AND t1.STKF_END = t2.CSO_END
			AND t1.STKF_TEKIYOYMD = t2.STKF_TEKIYOYMD;

  -- 削除対象レコードを編集
		UPDATE #wt_IMPORT_SOURYOU_102
		SET
			STKF_TEKIYOYMD = CSO_TEKIYOYMD,
			STKF_UPDATECNT = 0,
			STKF_DELFG = 2,
			STKF_INYMD = @NowDt,
			STKF_INTANTO = @Tanto,
			STKF_KOSINYMD = @NowDt,
			STKF_KOSINTANTO = @Tanto
		WHERE STKF_TEKIYOYMD < CSO_TEKIYOYMD;

		UPDATE #wt_IMPORT_SOURYOU_102
		SET
			STKF_DELFG = 2,
			STKF_KOSINYMD = @NowDt,
			STKF_KOSINTANTO = @Tanto
		WHERE STKF_TEKIYOYMD = CSO_TEKIYOYMD;
			
  -- ＤＢレコードを更新
		INSERT INTO TYUMON_KNR_MST_now
		SELECT STKF_KCD,
			STKF_HTCD,
			STKF_SCD,
			STKF_STR,
			STKF_END,
			STKF_TEKIYOYMD,
			STKF_UPDATECNT,
			STKF_HANEIYMD,
			STKF_SOURYO,
			STKF_NOWSURYO,
			STKF_SESSIONID,
			STKF_YDELKBN,
			STKF_MDELKBN,
			STKF_YOBI1,
			STKF_YOBI2,
			STKF_YOBI3,
			STKF_YOBI4,
			STKF_YOBI5,
			STKF_YOBI6,
			STKF_YOBI7,
			STKF_YOBI8,
			STKF_YOBI9,
			STKF_IMPORTYMD,
			STKF_IMPORTFILE,
			STKF_DELFG,
			STKF_INYMD,
			STKF_INTANTO,
			STKF_KOSINYMD,
			STKF_KOSINTANTO
		FROM #wt_IMPORT_SOURYOU_102;

-- [会社コード、店舗コード、商品コード] でマスタ削除（※ [適用日] 時点）
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_TEKIYOYMD, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_1
				WHERE CSO_MDELKBN = 2
			),
			t2 AS (
				SELECT DISTINCT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_TEKIYOYMD
				FROM t1
				INNER JOIN vi_TYUMON_KNR_MST t2
				ON t1.CSO_KCD = t2.STKF_KCD
					AND t1.CSO_TENCD = t2.STKF_HTCD
					AND t1.CSO_SCD = t2.STKF_SCD
					AND t1.CSO_TEKIYOYMD >= t2.STKF_TEKIYOYMD
					AND t1.CSO_TEKIYOYMD <= t2.STKF_TEKIYOYMD_END
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_TEKIYOYMD, t1.CSO_IMPORTFILE, t2.CSO_KCD AS CSO_KCD_2
		INTO #wt_IMPORT_SOURYOU_103
		FROM t1
		LEFT OUTER JOIN t2
		ON t1.CSO_KCD = t2.CSO_KCD
			AND t1.CSO_TENCD = t2.CSO_TENCD
			AND t1.CSO_SCD = t2.CSO_SCD
			AND t1.CSO_TEKIYOYMD = t2.CSO_TEKIYOYMD;

  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_TEKIYOYMD, CSO_IMPORTFILE
				FROM #wt_IMPORT_SOURYOU_103
				WHERE CSO_KCD_2 IS NULL
			)
		SELECT t1.CSO_KCD, t1.CSO_TENCD, t1.CSO_SCD, t1.CSO_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CSO_IMPORTFILE, LEN(t1.CSO_IMPORTFILE) - PATINDEX('%|%', t1.CSO_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CSO_KCD = t2.SSHM_KCD
			AND t1.CSO_TENCD = t2.SSHM_HTCD
			AND t1.CSO_SCD = t2.SSHM_SCD
			AND t1.CSO_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CSO_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t2 AS (
				SELECT DISTINCT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_TEKIYOYMD
				FROM #wt_IMPORT_SOURYOU_103
			)
		SELECT t1.*, t2.CSO_TEKIYOYMD
		INTO #wt_IMPORT_SOURYOU_104
		FROM vi_TYUMON_KNR_MST t1
		INNER JOIN t2
		ON t1.STKF_KCD = t2.CSO_KCD
			AND t1.STKF_HTCD = t2.CSO_TENCD
			AND t1.STKF_SCD = t2.CSO_SCD
			AND t1.STKF_TEKIYOYMD <= t2.CSO_TEKIYOYMD
			AND t1.STKF_TEKIYOYMD_END >= t2.CSO_TEKIYOYMD;

  -- 削除対象レコードを編集
		UPDATE #wt_IMPORT_SOURYOU_104
		SET
			STKF_TEKIYOYMD = CSO_TEKIYOYMD,
			STKF_UPDATECNT = 0,
			STKF_DELFG = 2,
			STKF_INYMD = @NowDt,
			STKF_INTANTO = @Tanto,
			STKF_KOSINYMD = @NowDt,
			STKF_KOSINTANTO = @Tanto
		WHERE STKF_TEKIYOYMD < CSO_TEKIYOYMD;

		UPDATE #wt_IMPORT_SOURYOU_104
		SET
			STKF_DELFG = 2,
			STKF_KOSINYMD = @NowDt,
			STKF_KOSINTANTO = @Tanto
		WHERE STKF_TEKIYOYMD = CSO_TEKIYOYMD;
			
  -- ＤＢレコードを更新
		INSERT INTO TYUMON_KNR_MST_now
		SELECT STKF_KCD,
			STKF_HTCD,
			STKF_SCD,
			STKF_STR,
			STKF_END,
			STKF_TEKIYOYMD,
			STKF_UPDATECNT,
			STKF_HANEIYMD,
			STKF_SOURYO,
			STKF_NOWSURYO,
			STKF_SESSIONID,
			STKF_YDELKBN,
			STKF_MDELKBN,
			STKF_YOBI1,
			STKF_YOBI2,
			STKF_YOBI3,
			STKF_YOBI4,
			STKF_YOBI5,
			STKF_YOBI6,
			STKF_YOBI7,
			STKF_YOBI8,
			STKF_YOBI9,
			STKF_IMPORTYMD,
			STKF_IMPORTFILE,
			STKF_DELFG,
			STKF_INYMD,
			STKF_INTANTO,
			STKF_KOSINYMD,
			STKF_KOSINTANTO
		FROM #wt_IMPORT_SOURYOU_104;

-- レコード登録
		SELECT t1.*, t2.*
		INTO #wt_IMPORT_SOURYOU_6
		FROM #wt_IMPORT_SOURYOU_1 t1
		LEFT OUTER JOIN TYUMON_KNR_MST_now t2
		ON t1.CSO_KCD = t2.STKF_KCD
			AND t1.CSO_TENCD = t2.STKF_HTCD
			AND t1.CSO_SCD = t2.STKF_SCD
			AND t1.CSO_TEKIYOYMD = t2.STKF_TEKIYOYMD
			AND t1.CSO_STR = t2.STKF_STR
			AND t1.CSO_END = t2.STKF_END;

  -- レコード更新
    -- 予約・マスタ 削除レコード
		INSERT INTO TYUMON_KNR_MST_now
		SELECT
			STKF_KCD,
			STKF_HTCD,
			STKF_SCD,
			STKF_STR,
			STKF_END,
			STKF_TEKIYOYMD,
			STKF_UPDATECNT,
			STKF_HANEIYMD,
			STKF_SOURYO,
			STKF_NOWSURYO,
			STKF_SESSIONID,
			CSO_YDELKBN,
			CSO_MDELKBN,
			STKF_YOBI1,
			STKF_YOBI2,
			STKF_YOBI3,
			STKF_YOBI4,
			STKF_YOBI5,
			STKF_YOBI6,
			STKF_YOBI7,
			STKF_YOBI8,
			STKF_YOBI9,
			CSO_IMPORTYMD,
			CSO_IMPORTFILE,
			STKF_DELFG,
			STKF_INYMD,
			STKF_INTANTO,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SOURYOU_6
		WHERE STKF_KCD IS NOT NULL
			AND CSO_YDELKBN + CSO_MDELKBN > 0;

    -- 通常レコード
		INSERT INTO TYUMON_KNR_MST_now
		SELECT
			STKF_KCD,
			STKF_HTCD,
			STKF_SCD,
			STKF_STR,
			STKF_END,
			STKF_TEKIYOYMD,
			STKF_UPDATECNT,
			CSO_HANEIYMD,
			CSO_SOURYO,
			STKF_NOWSURYO,
			STKF_SESSIONID,
			CSO_YDELKBN,
			CSO_MDELKBN,
			CSO_YOBI1,
			CSO_YOBI2,
			CSO_YOBI3,
			CSO_YOBI4,
			CSO_YOBI5,
			CSO_YOBI6,
			CSO_YOBI7,
			CSO_YOBI8,
			CSO_YOBI9,
			CSO_IMPORTYMD,
			CSO_IMPORTFILE,
			0,
			STKF_INYMD,
			STKF_INTANTO,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SOURYOU_6
		WHERE STKF_KCD IS NOT NULL
			AND CSO_YDELKBN = 0 AND CSO_MDELKBN = 0;

  -- レコード追加
    -- 予約・マスタ 削除レコード
		INSERT INTO TYUMON_KNR_MST_now
		SELECT
			CSO_KCD,
			CSO_TENCD,
			CSO_SCD,
			CSO_STR,
			CSO_END,
			CSO_TEKIYOYMD,
			0,
			CSO_HANEIYMD,
			CSO_SOURYO,
			0,
			NULL,
			CSO_YDELKBN,
			CSO_MDELKBN,
			CSO_YOBI1,
			CSO_YOBI2,
			CSO_YOBI3,
			CSO_YOBI4,
			CSO_YOBI5,
			CSO_YOBI6,
			CSO_YOBI7,
			CSO_YOBI8,
			CSO_YOBI9,
			CSO_IMPORTYMD,
			CSO_IMPORTFILE,
			1,
			@NowDt,
			@Tanto,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SOURYOU_6
		WHERE STKF_KCD IS NULL
			AND CSO_YDELKBN + CSO_MDELKBN > 0;
			
    -- 通常レコード
		INSERT INTO TYUMON_KNR_MST_now
		SELECT
			CSO_KCD,
			CSO_TENCD,
			CSO_SCD,
			CSO_STR,
			CSO_END,
			CSO_TEKIYOYMD,
			0,
			CSO_HANEIYMD,
			CSO_SOURYO,
			0,
			NULL,
			CSO_YDELKBN,
			CSO_MDELKBN,
			CSO_YOBI1,
			CSO_YOBI2,
			CSO_YOBI3,
			CSO_YOBI4,
			CSO_YOBI5,
			CSO_YOBI6,
			CSO_YOBI7,
			CSO_YOBI8,
			CSO_YOBI9,
			CSO_IMPORTYMD,
			CSO_IMPORTFILE,
			0,
			@NowDt,
			@Tanto,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_SOURYOU_6
		WHERE STKF_KCD IS NULL
			AND CSO_YDELKBN = 0 AND CSO_MDELKBN = 0;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_IMPORT_SOURYOU_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
