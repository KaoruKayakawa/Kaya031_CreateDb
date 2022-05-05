USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_WITH_SHOHIN_MST]') AND type in (N'P'))
DROP PROCEDURE [dbo].[UPDATE_WITH_SHOHIN_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: UPDATE_WITH_SHOHIN_MST
-- 機能			: BASE DB SHOHIN_MST_now の内容を、JYUCYU DB SHOHIN_M_now・SHOHIN_M・SHOHIN_SHOSAI_M_now・SHOHIN_SHOSAI_M に反映する。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/06/29  作成者 : 茅川
-- 更新			: 2021/10/19　茅川
-- 　　			: 2021/11/01　茅川
--					: 2021/12/08　茅川
--					: 2022/02/02　茅川
--					: 2022/02/25　茅川
-- ====================================================
CREATE PROCEDURE [dbo].[UPDATE_WITH_SHOHIN_MST]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_UPDATE_WITH_SHOHIN_MST_1;
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
		DECLARE @valInt int;
		SELECT @valInt = CAST(ASTM_SETVALUE AS int) FROM APP_SETTING_M WHERE ASTM_SETKBN = 'CalendarTekiyoCount' AND ASTM_SETDTLKBN ='X';

		IF @valInt IS NULL
		BEGIN
			SET @ErrMessage = N'テーブル [APP_SETTING_M] に "CalendarTekiyoCount" の設定が見つかりません。';
			SET @ErrSeverity = 11;
			SET @ErrState = 1;

			RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
		END
		
		DECLARE @nowDt datetime = GETDATE();
		DECLARE @nowYmd datetime = CAST(@nowDt AS date);
		DECLARE @tekiYmd datetime = DATEADD(day, @valInt, @nowYmd);
		DECLARE @delYmd datetime = DATEADD(day, -10, @nowYmd);

		DECLARE @db_opeEnv varchar(256);
		SELECT @db_opeEnv = ASTM_SETVALUE FROM APP_SETTING_M WHERE ASTM_SETKBN = 'DatabaseOperatingEnvironment' AND ASTM_SETDTLKBN ='X';

		IF @db_opeEnv IS NULL
		BEGIN
			SET @ErrMessage = N'テーブル [APP_SETTING_M] に "DatabaseOperatingEnvironment" の設定が見つかりません。';
			SET @ErrSeverity = 11;
			SET @ErrState = 1;

			RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
		END

		DECLARE @propName_base sysname = N'UPDATE_WITH_SHOHIN_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		DECLARE @lastExeDt1 datetime, @lastExeDt2 datetime;

		SELECT @lastExeDt1 = CAST(value AS datetime)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'SHOHIN_MST_now'
			AND [name] = @propName_base;

		IF @lastExeDt1 IS NULL
		BEGIN
			SET @lastExeDt2 = @nowDt;

			EXEC #{-BASE_DB-}#.sys.sp_addextendedproperty @name = @propName_base,
				@value = @lastExeDt2,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'SHOHIN_MST_now';

			SET @lastExeDt1 = '2000-12-31 23:59:59';
		END;
		ELSE
		BEGIN
			-- システム日時がメンテナンスされている場合を考慮
			IF @nowDt > @lastExeDt1
				SET @lastExeDt2 = @nowDt;
			ELSE
				SET @lastExeDt2= DATEADD(second, 1, @lastExeDt1);
				
			EXEC #{-BASE_DB-}#.sys.sp_updateextendedproperty @name = @propName_base,
				@value = @lastExeDt2 ,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'SHOHIN_MST_now';
		END;

		SELECT *,
			dbo.CONVERT_HTCD(SSHM_KCD, SSHM_HTCD) AS TENCD,
			CAST(NULL AS datetime) AS DISPPERIODSTR, CAST(NULL AS datetime) AS DISPPERIODEND
		INTO #wt_UPDATE_WITH_SHOHIN_MST_101
		FROM SHOHIN_MST_now
		WHERE SSHM_KOSINYMD > @lastExeDt1;

		-- [価格マスタ].[TOKUTANKA] 再計算のため、保留レコードに登録する。
		WITH
			t1 AS (
				SELECT SSHM_KCD, SSHM_HTCD, SSHM_SCD, SSHM_TEKIYOYMD
				FROM #wt_UPDATE_WITH_SHOHIN_MST_101
				WHERE SSHM_FUTEIKANKBN = 1
			),
			t2 AS (
				SELECT t1.SSHM_KCD, t1.SSHM_HTCD, t1.SSHM_SCD, t1.SSHM_TEKIYOYMD, a.SSHM_TEKIYOYMD_END
				FROM t1
				INNER JOIN vi_SHOHIN_MST a
				ON t1.SSHM_KCD = a.SSHM_KCD
					AND t1.SSHM_HTCD = a.SSHM_HTCD
					AND t1.SSHM_SCD = a.SSHM_SCD
					AND t1.SSHM_TEKIYOYMD = a.SSHM_TEKIYOYMD
			),
			t3 AS (
				SELECT *
				FROM UPDATE_PENDING
				WHERE UDP_TBL = N'KAKAKU_MST'
			)
		INSERT INTO UPDATE_PENDING (
			UDP_TBL,
			UDP_KCD,
			UDP_HTCD,
			UDP_TEKIYOYMD,
			UDP_UPDATECNT,
			UDP_KEY1,
			UDP_KEY2,
			UDP_NOTE,
			UDP_TENCD
		)
		SELECT
			CAST(N'KAKAKU_MST' AS nvarchar(50)),
			t4.SKAK_KCD,
			t4.SKAK_HTCD,
			t4.SKAK_TEKIYOYMD,
			t4.SKAK_UPDATECNT,
			t4.SKAK_SCD,
			t4.SKAK_KIKAKUCD,
			N'[商品] 更新（SHOHIN_MST_now）',
			dbo.CONVERT_HTCD(t4.SKAK_KCD, t4.SKAK_HTCD)
		FROM t2
		INNER JOIN KAKAKU_MST_now t4
		ON t2.SSHM_KCD = t4.SKAK_KCD
			AND t2.SSHM_HTCD = t4.SKAK_HTCD
			AND t2.SSHM_SCD = t4.SKAK_SCD
			AND (t4.SKAK_TEKIYOYMD BETWEEN t2.SSHM_TEKIYOYMD AND t2.SSHM_TEKIYOYMD_END)
		LEFT OUTER JOIN t3
		ON t4.SKAK_KCD = t3.UDP_KCD
			AND t4.SKAK_HTCD = t3.UDP_HTCD
			AND t4.SKAK_SCD = CAST(t3.UDP_KEY1 AS bigint)
			AND t4.SKAK_KIKAKUCD = CAST(t3.UDP_KEY2 AS bigint)
			AND t4.SKAK_TEKIYOYMD = t3.UDP_TEKIYOYMD
			AND t4.SKAK_UPDATECNT = t3.UDP_UPDATECNT
		WHERE t3.UDP_TBL IS NULL;

		-- 新規レコードの [適用日] 以外のプライマリキーが一致するレコードを、更新対象に含める。
		-- ※ 本プロシージャでの削除処理を、正しく行うために必要。
		WITH
			t1 AS (
				SELECT DISTINCT SSHM_KCD, SSHM_HTCD, SSHM_SCD
				FROM #wt_UPDATE_WITH_SHOHIN_MST_101
			),
			t2 AS (
				SELECT a.*
				FROM SHOHIN_MST_now a
				INNER JOIN t1
				ON a.SSHM_KCD = t1.SSHM_KCD
					AND a.SSHM_HTCD = t1.SSHM_HTCD
					AND a.SSHM_SCD = t1.SSHM_SCD
				LEFT OUTER JOIN #wt_UPDATE_WITH_SHOHIN_MST_101 b
				ON a.SSHM_KCD = b.SSHM_KCD
					AND a.SSHM_HTCD = b.SSHM_HTCD
					AND a.SSHM_SCD = b.SSHM_SCD
					AND a.SSHM_TEKIYOYMD = b.SSHM_TEKIYOYMD
				WHERE b.SSHM_KCD IS NULL
			)
		INSERT INTO #wt_UPDATE_WITH_SHOHIN_MST_101
		SELECT *, dbo.CONVERT_HTCD(SSHM_KCD, SSHM_HTCD) AS TENCD,
			CAST(NULL AS datetime) AS DISPPERIODSTR, CAST(NULL AS datetime) AS DISPPERIODEND
		FROM t2;

		/* 現状において、保留は発生しない
		-- 保留レコードを登録対象に含める ->
		WITH
			t2 AS (
				SELECT *
				FROM UPDATE_PENDING
				WHERE UDP_TBL = N'SHOHIN_MST'
			)
		INSERT INTO #wt_UPDATE_WITH_SHOHIN_MST_101
		SELECT t1.*,  t2.UDP_TENCD, NULL, NULL
		FROM SHOHIN_MST_now t1
		INNER JOIN t2
		ON t1.SSHM_KCD = t2.UDP_KCD
			AND t1.SSHM_HTCD = t2.UDP_HTCD
			AND t1.SSHM_TEKIYOYMD = t2.UDP_TEKIYOYMD
			AND t1.SSHM_UPDATECNT = t2.UDP_UPDATECNT			-- 更新されたレコードは除く
			AND t1.SSHM_SCD = CAST(t2.UDP_KEY1 AS bigint)
		LEFT OUTER JOIN #wt_UPDATE_WITH_SHOHIN_MST_101 t3		-- 重複する場合もあるので考慮にいれる
		ON t1.SSHM_KCD = t3.SSHM_KCD
			AND t1.SSHM_HTCD = t3.SSHM_HTCD
			AND t1.SSHM_TEKIYOYMD = t3.SSHM_TEKIYOYMD
			AND t1.SSHM_SCD = t3.SSHM_SCD
		WHERE t3.SSHM_KCD IS NULL;
			
		DELETE FROM UPDATE_PENDING
		WHERE UDP_TBL = N'SHOHIN_MST';
		-- <- 保留レコードを登録対象に含める
		*/

		UPDATE #wt_UPDATE_WITH_SHOHIN_MST_101
		SET DISPPERIODSTR = SSHM_HAISTR,
			DISPPERIODEND = SSHM_HAIEND
		WHERE SSHM_TOBASHIDISPKBN <> 1 OR SSHM_TOBASHIDISPKBN IS NULL;

		IF @db_opeEnv = 'verify'
		BEGIN
			DECLARE @day1 datetime = CAST(GETDATE() AS date);

			UPDATE #wt_UPDATE_WITH_SHOHIN_MST_101
			SET SSHM_JUCHUSTR = @day1
			WHERE SSHM_JUCHUSTR > @day1;
		END;

		-- SHOHIN_M
		DELETE a
		FROM SHOHIN_M_now a
		INNER JOIN #wt_UPDATE_WITH_SHOHIN_MST_101 b
		ON a.SHM_HTCD = b.TENCD
			AND a.SHM_SCD = b.SSHM_SCD
			AND a.SHM_TEKIYOYMD = b.SSHM_TEKIYOYMD;

		INSERT INTO SHOHIN_M_now
		SELECT
			TENCD,
			SSHM_SCD,
			SSHM_TEKIYOYMD,
			SSHM_UPDATECNT,
			SSHM_JANCD1,
			SSHM_BUMONCD,
			SSHM_SHONAME,
			SSHM_MAKNAME,
			NULL,
			dbo.CONVERT_SURYOSEIGEN(SSHM_SURYOSEIGEN_M, SSHM_SEIGYOKBN, SSHM_TEISHIKBN),
			SSHM_TANKA,
			SSHM_YOUKIKBN,
			SSHM_JUNOUKIKAN,
			SSHM_JUCHUSTR,
			SSHM_JUCHUEND,
			SSHM_HAISTR,
			SSHM_HAIEND,
			SSHM_HAITEISTR,
			SSHM_HAITEIEND,
			SSHM_KEISAIPAGE + SSHM_KEISAIJUN,
			SSHM_YOUBIKBN,
			dbo.CONVERT_URIZEIKBN(SSHM_URIZEIKBN),
			dbo.CONVERT_FILENAME(SSHM_SFILENAME, SSHM_SCD),
			dbo.CONVERT_KEISAIFLG(SSHM_KEISAIFLG),
			dbo.CONVERT_FAVBTNFLG(SSHM_FAVBTNDFLG),
			SSHM_TYUKNRFLG,
			SSHM_SJKBN,
			SSHM_SEBANGO,
			0,
			SSHM_KEYWORD,
			SSHM_NEWSORTKEY,
			SSHM_SIMETIME,
			DISPPERIODSTR,
			DISPPERIODEND,
			SSHM_ZEIRITUKBN,
			SSHM_COMMENTDISPFLG,
			SSHM_100BAIKA,
			SSHM_MAXGRAM,
			SSHM_MINGRAM,
			SSHM_FUTEIKANKBN,
			SSHM_DELFG,
			SSHM_INYMD,
			SSHM_INTANTO,
			SSHM_KOSINYMD,
			SSHM_KOSINTANTO
		FROM #wt_UPDATE_WITH_SHOHIN_MST_101
		WHERE SSHM_DELFG <> 1;

		-- 不要レコード削除（適用日）
		DELETE a
		FROM SHOHIN_M_now a
		LEFT OUTER JOIN ft_SHOHIN_M(@delYmd) b
		ON a.SHM_HTCD = b.SHM_HTCD
			AND a.SHM_SCD = b.SHM_SCD
		WHERE a.SHM_TEKIYOYMD < b.SHM_TEKIYOYMD
			OR (b.SHM_TEKIYOYMD IS NULL AND a.SHM_TEKIYOYMD <= @delYmd);

		-- 不要レコード削除（配達終了日）	※ プライマリーキー単位での削除
		WITH
			t2 AS (
				SELECT SHM_HTCD, SHM_SCD
				FROM SHOHIN_M_now
				GROUP BY SHM_HTCD, SHM_SCD
				HAVING MAX(SHM_HAIEND) < @delYmd
			)
		DELETE t1
		FROM SHOHIN_M_now t1
		INNER JOIN t2
		ON t1.SHM_HTCD = t2.SHM_HTCD
			AND t1.SHM_SCD = t2.SHM_SCD;
			
		-- テーブル SHOHIN_M の更新（日替わりの一回目は TRUNCATE を行い、全レコードを再作成する） ->
		DECLARE @propName_app sysname = N'UPDATE_WITH_SHOHIN_MST__Truncate_DateTime';
		DECLARE @truncDt datetime;

		SELECT @truncDt = CAST(value AS datetime)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[SHOHIN_M]')
			AND name = @propName_app;

		IF @truncDt IS NULL
		BEGIN
			SET @truncDt = DATEADD(day, -1, @nowDt);

			EXEC sys.sp_addextendedproperty @name = @propName_app,
				@value = @truncDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'SHOHIN_M';
		END;

		IF CAST(@truncDt AS date) < @nowYmd
		BEGIN
			TRUNCATE TABLE SHOHIN_M;

			INSERT INTO SHOHIN_M
			SELECT
				SHM_HTCD,
				SHM_SCD,
				SHM_JANCD,
				SHM_BUMONCD,
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
				SHM_SIMETIME,
				SHM_INYMD,
				SHM_KOSINYMD,
				SHM_KOSINYMD,
				SHM_DISPPERIODSTR,
				SHM_DISPPERIODEND,
				SHM_TAXKBN,
				SHM_COMMENTDISPFLG,
				SHM_100BAIKA,
				SHM_MAXGRAM,
				SHM_MINGRAM,
				SHM_FUTEIKANKBN
			FROM ft_SHOHIN_M(@tekiYmd);

			EXEC sys.sp_updateextendedproperty @name = @propName_app,
				@value = @nowDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'SHOHIN_M';
		END;
		ELSE
		BEGIN
			SELECT DISTINCT
				TENCD,
				SSHM_SCD
			INTO #wt_UPDATE_WITH_SHOHIN_MST_102
			FROM #wt_UPDATE_WITH_SHOHIN_MST_101;

			DELETE a
			FROM SHOHIN_M a
			INNER JOIN #wt_UPDATE_WITH_SHOHIN_MST_102 b
			ON a.SHM_HTCD = b.TENCD
				AND a.SHM_SCD = b.SSHM_SCD;

			INSERT INTO SHOHIN_M
			SELECT
				SHM_HTCD,
				SHM_SCD,
				SHM_JANCD,
				SHM_BUMONCD,
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
				SHM_SIMETIME,
				SHM_INYMD,
				SHM_KOSINYMD,
				SHM_KOSINYMD,
				SHM_DISPPERIODSTR,
				SHM_DISPPERIODEND,
				SHM_TAXKBN,
				SHM_COMMENTDISPFLG,
				SHM_100BAIKA,
				SHM_MAXGRAM,
				SHM_MINGRAM,
				SHM_FUTEIKANKBN
			FROM ft_SHOHIN_M(@tekiYmd) a
			INNER JOIN #wt_UPDATE_WITH_SHOHIN_MST_102 b
			ON a.SHM_HTCD = b.TENCD
				AND a.SHM_SCD = b.SSHM_SCD;

			DROP TABLE #wt_UPDATE_WITH_SHOHIN_MST_102;
		END;
		-- <- テーブル SHOHIN_M の更新（日替わりの一回目は、TRUNCATE を行い、全レコードを再作成する）
		
		-- 不要レコード削除（配達終了日）	※ プライマリーキー単位削除が行われなかったレコード
		DELETE FROM SHOHIN_M
		WHERE SHM_HAIEND < @delYmd;

		-- SHOHIN_SHOSAI_M

		DELETE a
		FROM SHOHIN_SHOSAI_M_now a
		INNER JOIN #wt_UPDATE_WITH_SHOHIN_MST_101 b
		ON a.SSM_HTCD = b.TENCD
			AND a.SSM_SCD = b.SSHM_SCD
			AND a.SSM_TEKIYOYMD = b.SSHM_TEKIYOYMD;

		INSERT INTO SHOHIN_SHOSAI_M_now
		SELECT
			TENCD,
			SSHM_SCD,
			SSHM_TEKIYOYMD,
			SSHM_UPDATECNT,
			SSHM_NAIYO,
			SSHM_GENZAIRYO,
			ISNULL(SSHM_ALLERGEN, '') + ISNULL(SSHM_SEIBUN, ''),
			SSHM_DELFG,
			SSHM_INYMD,
			SSHM_INTANTO,
			SSHM_KOSINYMD,
			SSHM_KOSINTANTO
		FROM #wt_UPDATE_WITH_SHOHIN_MST_101
		WHERE SSHM_DELFG <> 1;

		-- 不要レコード削除（商品コード）
		DELETE a
		FROM SHOHIN_SHOSAI_M_now a
		LEFT OUTER JOIN vi_SHOHIN_M b
		ON a.SSM_HTCD = b.SHM_HTCD
			AND a.SSM_SCD = b.SHM_SCD
			AND (a.SSM_TEKIYOYMD BETWEEN b.SHM_TEKIYOYMD AND b.SHM_TEKIYOYMD_END)
		WHERE b.SHM_HTCD IS NULL;
		
		-- テーブル SHOHIN_SHOSAI_M の更新（日替わりの一回目は TRUNCATE を行い、全レコードを再作成する） ->
		IF CAST(@truncDt AS date) < @nowYmd
		BEGIN
			TRUNCATE TABLE SHOHIN_SHOSAI_M;

			INSERT INTO SHOHIN_SHOSAI_M
			SELECT
				SSM_HTCD,
				SSM_SCD,
				SSM_NAIYO,
				SSM_GENZAIRYO,
				SSM_SEIBUN,
				SSM_INYMD,
				SSM_KOSINYMD,
				SSM_KOSINYMD
			FROM ft_SHOHIN_SHOSAI_M(@tekiYmd);
		END;
		ELSE
		BEGIN
			SELECT DISTINCT
				TENCD,
				SSHM_SCD
			INTO #wt_UPDATE_WITH_SHOHIN_MST_103
			FROM #wt_UPDATE_WITH_SHOHIN_MST_101;

			DELETE a
			FROM SHOHIN_SHOSAI_M a
			INNER JOIN #wt_UPDATE_WITH_SHOHIN_MST_103 b
			ON a.SSM_HTCD = b.TENCD
				AND a.SSM_SCD = b.SSHM_SCD;

			INSERT INTO SHOHIN_SHOSAI_M
			SELECT
				a.SSM_HTCD,
				a.SSM_SCD,
				a.SSM_NAIYO,
				a.SSM_GENZAIRYO,
				a.SSM_SEIBUN,
				a.SSM_INYMD,
				a.SSM_KOSINYMD,
				a.SSM_KOSINYMD
			FROM ft_SHOHIN_SHOSAI_M(@tekiYmd) a
			INNER JOIN #wt_UPDATE_WITH_SHOHIN_MST_103 b
			ON a.SSM_HTCD = b.TENCD
				AND a.SSM_SCD = b.SSHM_SCD;

			DROP TABLE #wt_UPDATE_WITH_SHOHIN_MST_103;
		END;
		-- <- テーブル SHOHIN_SHOSAI_M の更新（日替わりの一回目は、TRUNCATE を行い、全レコードを再作成する）

		DROP TABLE #wt_UPDATE_WITH_SHOHIN_MST_101;

		-- 不要レコード削除（商品コード）
		DELETE a
		FROM SHOHIN_SHOSAI_M a
		LEFT OUTER JOIN SHOHIN_M b
		ON a.SSM_HTCD = b.SHM_HTCD
			AND a.SSM_SCD = b.SHM_SCD
		WHERE b.SHM_HTCD IS NULL;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0
			ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_UPDATE_WITH_SHOHIN_MST_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH
END
GO
