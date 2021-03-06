USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IMPORT_MIXMSHOHIN]') AND type in (N'P'))
DROP PROCEDURE [dbo].[IMPORT_MIXMSHOHIN]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: IMPORT_MIXMSHOHIN
-- 機能			: テーブル MIXMATCH_MST_now に CSV データを取り込む。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/05/04  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[IMPORT_MIXMSHOHIN]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_IMPORT_MIXMSHOHIN_1;
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
		DECLARE @Tanto varchar(100) = 'sqlserv_proc_IMPORT_MIXMSHOHIN';

-- [会社コード、店舗コード、ミックスマッチ番号、商品コード、適用日] で予約削除
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_MMNO, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_1
				WHERE CMS_YDELKBN = 1
			),
			t2 AS (
				SELECT SMIM_KCD, SMIM_HTCD, SMIM_MMNOBIG, SMIM_SCD, SMIM_TEKIYOYMD
				FROM MIXMATCH_MST_now
				WHERE SMIM_DELFG <> 1
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_MMNO, t1.CMS_SCD, t1.CMS_TEKIYOYMD, t1.CMS_IMPORTFILE, t2.SMIM_KCD AS CMS_KCD_2
		INTO #wt_IMPORT_MIXMSHOHIN_2
		FROM t1
		LEFT OUTER JOIN t2
		ON t1.CMS_KCD = t2.SMIM_KCD
			AND t1.CMS_TENCD = t2.SMIM_HTCD
			AND t1.CMS_MMNO = t2.SMIM_MMNOBIG
			AND t1.CMS_SCD = t2.SMIM_SCD
			AND t1.CMS_TEKIYOYMD = t2.SMIM_TEKIYOYMD;

  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_MMNO, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_2
				WHERE CMS_KCD_2 IS NULL
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_MMNO, t1.CMS_SCD, t1.CMS_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CMS_IMPORTFILE, LEN(t1.CMS_IMPORTFILE) - PATINDEX('%|%', t1.CMS_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CMS_KCD = t2.SSHM_KCD
			AND t1.CMS_TENCD = t2.SSHM_HTCD
			AND t1.CMS_SCD = t2.SSHM_SCD
			AND t1.CMS_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CMS_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM MIXMATCH_MST_now
				WHERE SMIM_DELFG <> 1
			)
		SELECT t1.*
		INTO #wt_IMPORT_MIXMSHOHIN_3
		FROM t1
		INNER JOIN #wt_IMPORT_MIXMSHOHIN_2 t2
		ON t1.SMIM_KCD = t2.CMS_KCD
			AND t1.SMIM_HTCD = t2.CMS_TENCD
			AND t1.SMIM_MMNOBIG = t2.CMS_MMNO
			AND t1.SMIM_SCD = t2.CMS_SCD
			AND t1.SMIM_TEKIYOYMD = t2.CMS_TEKIYOYMD;

  -- 削除対象レコードの [削除フラグ] を設定
		UPDATE #wt_IMPORT_MIXMSHOHIN_3
		SET
			SMIM_DELFG = 1,
			SMIM_KOSINYMD = @NowDt,
			SMIM_KOSINTANTO = @Tanto;
			
  -- ＤＢレコードを更新
		INSERT INTO MIXMATCH_MST_now
		SELECT *
		FROM #wt_IMPORT_MIXMSHOHIN_3;
		
-- [会社コード、店舗コード、商品コード] で予約削除（※ [適用日] 以降）
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_1
				WHERE CMS_YDELKBN = 2
			),
			t2 AS (
				SELECT SMIM_KCD, SMIM_HTCD, SMIM_SCD, SMIM_TEKIYOYMD
				FROM MIXMATCH_MST_now
				WHERE SMIM_DELFG <> 1
			),
			t3 AS (
				SELECT DISTINCT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_SCD, t1.CMS_TEKIYOYMD
				FROM t1
				INNER JOIN t2
				ON t1.CMS_KCD = t2.SMIM_KCD
					AND t1.CMS_TENCD = t2.SMIM_HTCD
					AND t1.CMS_SCD = t2.SMIM_SCD
					AND t1.CMS_TEKIYOYMD <= t2.SMIM_TEKIYOYMD
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_SCD, t1.CMS_TEKIYOYMD, t1.CMS_IMPORTFILE, t3.CMS_KCD AS CMS_KCD_2
		INTO #wt_IMPORT_MIXMSHOHIN_4
		FROM t1
		LEFT OUTER JOIN t3
		ON t1.CMS_KCD = t3.CMS_KCD
			AND t1.CMS_TENCD = t3.CMS_TENCD
			AND t1.CMS_SCD = t3.CMS_SCD
			AND t1.CMS_TEKIYOYMD = t3.CMS_TEKIYOYMD;
			
  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_4
				WHERE CMS_KCD_2 IS NULL
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_SCD, t1.CMS_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CMS_IMPORTFILE, LEN(t1.CMS_IMPORTFILE) - PATINDEX('%|%', t1.CMS_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CMS_KCD = t2.SSHM_KCD
			AND t1.CMS_TENCD = t2.SSHM_HTCD
			AND t1.CMS_SCD = t2.SSHM_SCD
			AND t1.CMS_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CMS_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM MIXMATCH_MST_now
				WHERE SMIM_DELFG <> 1
			),
			t2 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_SCD, MIN(CMS_TEKIYOYMD) AS CMS_TEKIYOYMD
				FROM #wt_IMPORT_MIXMSHOHIN_4
				WHERE CMS_KCD_2 IS NOT NULL
				GROUP BY CMS_KCD, CMS_TENCD, CMS_SCD
			)
		SELECT t1.*
		INTO #wt_IMPORT_MIXMSHOHIN_5
		FROM t1
		INNER JOIN t2
		ON t1.SMIM_KCD = t2.CMS_KCD
			AND t1.SMIM_HTCD = t2.CMS_TENCD
			AND t1.SMIM_SCD = t2.CMS_SCD
			AND t1.SMIM_TEKIYOYMD >= t2.CMS_TEKIYOYMD;
			
  -- 削除対象レコードの [削除フラグ] を設定
		UPDATE #wt_IMPORT_MIXMSHOHIN_5
		SET
			SMIM_DELFG = 1,
			SMIM_KOSINYMD = @NowDt,
			SMIM_KOSINTANTO = @Tanto;
			
  -- ＤＢレコードを更新
		INSERT INTO MIXMATCH_MST_now
		SELECT *
		FROM #wt_IMPORT_MIXMSHOHIN_5;

-- [会社コード、店舗コード、ミックスマッチ番号、商品コード] でマスタ削除（※ [適用日] 時点）
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_MMNO, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_1
				WHERE CMS_MDELKBN = 1
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_MMNO, t1.CMS_SCD, t1.CMS_TEKIYOYMD, t1.CMS_IMPORTFILE, t2.SMIM_TEKIYOYMD
		INTO #wt_IMPORT_MIXMSHOHIN_101
		FROM t1
		LEFT OUTER JOIN vi_MIXMATCH_MST t2
		ON t1.CMS_KCD = t2.SMIM_KCD
			AND t1.CMS_TENCD = t2.SMIM_HTCD
			AND t1.CMS_MMNO = t2.SMIM_MMNOBIG
			AND t1.CMS_SCD = t2.SMIM_SCD
			AND t1.CMS_TEKIYOYMD >= t2.SMIM_TEKIYOYMD
			AND t1.CMS_TEKIYOYMD <= t2.SMIM_TEKIYOYMD_END;

  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_MMNO, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_101
				WHERE SMIM_TEKIYOYMD IS NULL
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_MMNO, t1.CMS_SCD, t1.CMS_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CMS_IMPORTFILE, LEN(t1.CMS_IMPORTFILE) - PATINDEX('%|%', t1.CMS_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CMS_KCD = t2.SSHM_KCD
			AND t1.CMS_TENCD = t2.SSHM_HTCD
			AND t1.CMS_SCD = t2.SSHM_SCD
			AND t1.CMS_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CMS_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t1 AS (
				SELECT *
				FROM MIXMATCH_MST_now
				WHERE SMIM_DELFG = 0
			)
		SELECT t1.*, t2.CMS_TEKIYOYMD
		INTO #wt_IMPORT_MIXMSHOHIN_102
		FROM t1
		INNER JOIN #wt_IMPORT_MIXMSHOHIN_101 t2
		ON t1.SMIM_KCD = t2.CMS_KCD
			AND t1.SMIM_HTCD = t2.CMS_TENCD
			AND t1.SMIM_MMNOBIG = t2.CMS_MMNO
			AND t1.SMIM_SCD = t2.CMS_SCD
			AND t1.SMIM_TEKIYOYMD = t2.SMIM_TEKIYOYMD;

  -- 削除対象レコードを編集
		UPDATE #wt_IMPORT_MIXMSHOHIN_102
		SET
			SMIM_TEKIYOYMD = CMS_TEKIYOYMD,
			SMIM_UPDATECNT = 0,
			SMIM_DELFG = 2,
			SMIM_INYMD = @NowDt,
			SMIM_INTANTO = @Tanto,
			SMIM_KOSINYMD = @NowDt,
			SMIM_KOSINTANTO = @Tanto
		WHERE SMIM_TEKIYOYMD < CMS_TEKIYOYMD;

		UPDATE #wt_IMPORT_MIXMSHOHIN_102
		SET
			SMIM_DELFG = 2,
			SMIM_KOSINYMD = @NowDt,
			SMIM_KOSINTANTO = @Tanto
		WHERE SMIM_TEKIYOYMD = CMS_TEKIYOYMD;
			
  -- ＤＢレコードを更新
		INSERT INTO MIXMATCH_MST_now
		SELECT SMIM_KCD,
			SMIM_HTCD,
			SMIM_MMNO,
			SMIM_SCD,
			SMIM_TEKIYOYMD,
			SMIM_UPDATECNT,
			SMIM_HANEIYMD,
			SMIM_MMNOBIG,
			SMIM_YDELKBN,
			SMIM_MDELKBN,
			SMIM_YOBI1,
			SMIM_YOBI2,
			SMIM_YOBI3,
			SMIM_YOBI4,
			SMIM_YOBI5,
			SMIM_YOBI6,
			SMIM_YOBI7,
			SMIM_YOBI8,
			SMIM_YOBI9,
			SMIM_IMPORTYMD,
			SMIM_IMPORTFILE,
			SMIM_DELFG,
			SMIM_INYMD,
			SMIM_INTANTO,
			SMIM_KOSINYMD,
			SMIM_KOSINTANTO
		FROM #wt_IMPORT_MIXMSHOHIN_102;

-- [会社コード、店舗コード、商品コード] でマスタ削除（※ [適用日] 時点）
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_1
				WHERE CMS_MDELKBN = 2
			),
			t2 AS (
				SELECT DISTINCT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_SCD, t1.CMS_TEKIYOYMD
				FROM t1
				INNER JOIN vi_MIXMATCH_MST t2
				ON t1.CMS_KCD = t2.SMIM_KCD
					AND t1.CMS_TENCD = t2.SMIM_HTCD
					AND t1.CMS_SCD = t2.SMIM_SCD
					AND t1.CMS_TEKIYOYMD >= t2.SMIM_TEKIYOYMD
					AND t1.CMS_TEKIYOYMD <= t2.SMIM_TEKIYOYMD_END
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_SCD, t1.CMS_TEKIYOYMD, t1.CMS_IMPORTFILE, t2.CMS_KCD AS CMS_KCD_2
		INTO #wt_IMPORT_MIXMSHOHIN_103
		FROM t1
		LEFT OUTER JOIN t2
		ON t1.CMS_KCD = t2.CMS_KCD
			AND t1.CMS_TENCD = t2.CMS_TENCD
			AND t1.CMS_SCD = t2.CMS_SCD
			AND t1.CMS_TEKIYOYMD = t2.CMS_TEKIYOYMD;

  -- 削除対象レコードが存在しない削除設定を取得
		WITH
			t1 AS (
				SELECT CMS_KCD, CMS_TENCD, CMS_SCD, CMS_TEKIYOYMD, CMS_IMPORTFILE
				FROM #wt_IMPORT_MIXMSHOHIN_103
				WHERE CMS_KCD_2 IS NULL
			)
		SELECT t1.CMS_KCD, t1.CMS_TENCD, t1.CMS_SCD, t1.CMS_TEKIYOYMD,
			ISNULL(t2.SSHM_SHONAME, '') AS SSHM_SHONAME, RIGHT(t1.CMS_IMPORTFILE, LEN(t1.CMS_IMPORTFILE) - PATINDEX('%|%', t1.CMS_IMPORTFILE)) AS CSV_LINENO
		FROM t1
		LEFT OUTER JOIN vi_SHOHIN_MST t2
		ON t1.CMS_KCD = t2.SSHM_KCD
			AND t1.CMS_TENCD = t2.SSHM_HTCD
			AND t1.CMS_SCD = t2.SSHM_SCD
			AND t1.CMS_TEKIYOYMD >= t2.SSHM_TEKIYOYMD
			AND t1.CMS_TEKIYOYMD <= t2.SSHM_TEKIYOYMD_END;
		
  -- 削除対象レコードを取得
		WITH
			t2 AS (
				SELECT DISTINCT CMS_KCD, CMS_TENCD, CMS_SCD, CMS_TEKIYOYMD
				FROM #wt_IMPORT_MIXMSHOHIN_103
			)
		SELECT t1.*, t2.CMS_TEKIYOYMD
		INTO #wt_IMPORT_MIXMSHOHIN_104
		FROM vi_MIXMATCH_MST t1
		INNER JOIN t2
		ON t1.SMIM_KCD = t2.CMS_KCD
			AND t1.SMIM_HTCD = t2.CMS_TENCD
			AND t1.SMIM_SCD = t2.CMS_SCD
			AND t1.SMIM_TEKIYOYMD <= t2.CMS_TEKIYOYMD
			AND t1.SMIM_TEKIYOYMD_END >= t2.CMS_TEKIYOYMD;

  -- 削除対象レコードを編集
		UPDATE #wt_IMPORT_MIXMSHOHIN_104
		SET
			SMIM_TEKIYOYMD = CMS_TEKIYOYMD,
			SMIM_UPDATECNT = 0,
			SMIM_DELFG = 2,
			SMIM_INYMD = @NowDt,
			SMIM_INTANTO = @Tanto,
			SMIM_KOSINYMD = @NowDt,
			SMIM_KOSINTANTO = @Tanto
		WHERE SMIM_TEKIYOYMD < CMS_TEKIYOYMD;

		UPDATE #wt_IMPORT_MIXMSHOHIN_104
		SET
			SMIM_DELFG = 2,
			SMIM_KOSINYMD = @NowDt,
			SMIM_KOSINTANTO = @Tanto
		WHERE SMIM_TEKIYOYMD = CMS_TEKIYOYMD;
			
  -- ＤＢレコードを更新
		INSERT INTO MIXMATCH_MST_now
		SELECT SMIM_KCD,
			SMIM_HTCD,
			SMIM_MMNO,
			SMIM_SCD,
			SMIM_TEKIYOYMD,
			SMIM_UPDATECNT,
			SMIM_HANEIYMD,
			SMIM_MMNOBIG,
			SMIM_YDELKBN,
			SMIM_MDELKBN,
			SMIM_YOBI1,
			SMIM_YOBI2,
			SMIM_YOBI3,
			SMIM_YOBI4,
			SMIM_YOBI5,
			SMIM_YOBI6,
			SMIM_YOBI7,
			SMIM_YOBI8,
			SMIM_YOBI9,
			SMIM_IMPORTYMD,
			SMIM_IMPORTFILE,
			SMIM_DELFG,
			SMIM_INYMD,
			SMIM_INTANTO,
			SMIM_KOSINYMD,
			SMIM_KOSINTANTO
		FROM #wt_IMPORT_MIXMSHOHIN_104;

-- レコード登録
		SELECT t1.*, t2.*
		INTO #wt_IMPORT_MIXMSHOHIN_6
		FROM #wt_IMPORT_MIXMSHOHIN_1 t1
		LEFT OUTER JOIN MIXMATCH_MST_now t2
		ON t1.CMS_KCD = t2.SMIM_KCD
			AND t1.CMS_TENCD = t2.SMIM_HTCD
			AND t1.CMS_MMNO = t2.SMIM_MMNOBIG
			AND t1.CMS_SCD = t2.SMIM_SCD
			AND t1.CMS_TEKIYOYMD = t2.SMIM_TEKIYOYMD;

  -- レコード更新
    -- 予約・マスタ 削除レコード
		INSERT INTO MIXMATCH_MST_now
		SELECT
			SMIM_KCD,
			SMIM_HTCD,
			SMIM_MMNO,
			SMIM_SCD,
			SMIM_TEKIYOYMD,
			SMIM_UPDATECNT,
			SMIM_HANEIYMD,
			SMIM_MMNOBIG,
			CMS_YDELKBN,
			CMS_MDELKBN,
			SMIM_YOBI1,
			SMIM_YOBI2,
			SMIM_YOBI3,
			SMIM_YOBI4,
			SMIM_YOBI5,
			SMIM_YOBI6,
			SMIM_YOBI7,
			SMIM_YOBI8,
			SMIM_YOBI9,
			CMS_IMPORTYMD,
			CMS_IMPORTFILE,
			SMIM_DELFG,
			SMIM_INYMD,
			SMIM_INTANTO,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_MIXMSHOHIN_6
		WHERE SMIM_KCD IS NOT NULL
			AND CMS_YDELKBN + CMS_MDELKBN > 0;
			
    -- 通常レコード
		INSERT INTO MIXMATCH_MST_now
		SELECT
			SMIM_KCD,
			SMIM_HTCD,
			SMIM_MMNO,
			SMIM_SCD,
			SMIM_TEKIYOYMD,
			SMIM_UPDATECNT,
			CMS_HANEIYMD,
			SMIM_MMNOBIG,
			CMS_YDELKBN,
			CMS_MDELKBN,
			CMS_YOBI1,
			CMS_YOBI2,
			CMS_YOBI3,
			CMS_YOBI4,
			CMS_YOBI5,
			CMS_YOBI6,
			CMS_YOBI7,
			CMS_YOBI8,
			CMS_YOBI9,
			CMS_IMPORTYMD,
			CMS_IMPORTFILE,
			0,
			SMIM_INYMD,
			SMIM_INTANTO,
			@NowDt,
			@Tanto
		FROM #wt_IMPORT_MIXMSHOHIN_6
		WHERE SMIM_KCD IS NOT NULL
			AND CMS_YDELKBN = 0 AND CMS_MDELKBN = 0;


  -- レコード追加
    -- 予約・マスタ 削除レコード
		WITH
			t1 AS (
				SELECT *
				FROM #wt_IMPORT_MIXMSHOHIN_6
				WHERE SMIM_KCD IS NULL
					AND CMS_YDELKBN + CMS_MDELKBN > 0
			)
		INSERT INTO MIXMATCH_MST_now
		SELECT
			t1.CMS_KCD,
			t1.CMS_TENCD,
			t2.MMNO,
			t1.CMS_SCD,
			t1.CMS_TEKIYOYMD,
			0,
			t1.CMS_HANEIYMD,
			t1.CMS_MMNO,
			t1.CMS_YDELKBN,
			t1.CMS_MDELKBN,
			t1.CMS_YOBI1,
			t1.CMS_YOBI2,
			t1.CMS_YOBI3,
			t1.CMS_YOBI4,
			t1.CMS_YOBI5,
			t1.CMS_YOBI6,
			t1.CMS_YOBI7,
			t1.CMS_YOBI8,
			t1.CMS_YOBI9,
			t1.CMS_IMPORTYMD,
			t1.CMS_IMPORTFILE,
			1,
			@NowDt,
			@Tanto,
			@NowDt,
			@Tanto
		FROM t1
		LEFT OUTER JOIN MIXMATCH_MMNO t2
		ON t1.CMS_MMNO = t2.CSVMMNO;
			
    -- 通常レコード
		WITH
			t1 AS (
				SELECT *
				FROM #wt_IMPORT_MIXMSHOHIN_6
				WHERE SMIM_KCD IS NULL
					AND CMS_YDELKBN = 0 AND CMS_MDELKBN = 0
			)
		INSERT INTO MIXMATCH_MST_now
		SELECT
			t1.CMS_KCD,
			t1.CMS_TENCD,
			t2.MMNO,
			t1.CMS_SCD,
			t1.CMS_TEKIYOYMD,
			0,
			t1.CMS_HANEIYMD,
			t1.CMS_MMNO,
			t1.CMS_YDELKBN,
			t1.CMS_MDELKBN,
			t1.CMS_YOBI1,
			t1.CMS_YOBI2,
			t1.CMS_YOBI3,
			t1.CMS_YOBI4,
			t1.CMS_YOBI5,
			t1.CMS_YOBI6,
			t1.CMS_YOBI7,
			t1.CMS_YOBI8,
			t1.CMS_YOBI9,
			t1.CMS_IMPORTYMD,
			t1.CMS_IMPORTFILE,
			0,
			@NowDt,
			@Tanto,
			@NowDt,
			@Tanto
		FROM t1
		LEFT OUTER JOIN MIXMATCH_MMNO t2
		ON t1.CMS_MMNO = t2.CSVMMNO;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_IMPORT_MIXMSHOHIN_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
