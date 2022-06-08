USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_WITH_TYUMON_KNR_MST]') AND type in (N'P'))
DROP PROCEDURE [dbo].[UPDATE_WITH_TYUMON_KNR_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: UPDATE_WITH_TYUMON_KNR_MST
-- 機能			: BASE DB TYUMON_KNR_MST_now の内容を、JYUCYU DB TYUMON_KNR_F_now・TYUMON_KNR_F に反映する。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/07/13  作成者 : 茅川
-- 更新			: 2021/10/19　茅川
--					: 2021/12/08　茅川
--					: 2022/02/25　茅川
--					: 2022/05/09　茅川
-- ====================================================
CREATE PROCEDURE [dbo].[UPDATE_WITH_TYUMON_KNR_MST]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_UPDATE_WITH_TYUMON_KNR_MST;
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

		DECLARE @propName_base sysname = N'UPDATE_WITH_TYUMON_KNR_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		DECLARE @lastExeDt1 datetime, @lastExeDt2 datetime;

		SELECT @lastExeDt1 = CAST(value AS datetime)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'TYUMON_KNR_MST_now'
			AND [name] = @propName_base;

		IF @lastExeDt1 IS NULL
		BEGIN
			SET @lastExeDt2 = @nowDt;

			EXEC #{-BASE_DB-}#.sys.sp_addextendedproperty @name = @propName_base,
				@value = @lastExeDt2,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'TYUMON_KNR_MST_now';

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
				@level1name = N'TYUMON_KNR_MST_now';
		END;

		SELECT *, dbo.CONVERT_HTCD(STKF_KCD, STKF_HTCD) AS TENCD
		INTO #wt_UPDATE_WITH_TYUMON_KNR_MST_101
		FROM TYUMON_KNR_MST_now
		WHERE STKF_KOSINYMD > @lastExeDt1;
		
		-- 新規レコードの [適用日] 以外のプライマリキーが一致するレコードを、更新対象に含める。
		-- ※ 本プロシージャでの削除処理を、正しく行うために必要。
		SELECT DISTINCT STKF_KCD, STKF_HTCD, STKF_SCD, STKF_STR, STKF_END
		INTO #wt_UPDATE_WITH_TYUMON_KNR_MST_101_1
		FROM #wt_UPDATE_WITH_TYUMON_KNR_MST_101;

		WITH
			t1 AS (
				SELECT a.*
				FROM TYUMON_KNR_MST_now a
				INNER JOIN #wt_UPDATE_WITH_TYUMON_KNR_MST_101_1 b
				ON a.STKF_KCD = b.STKF_KCD
					AND a.STKF_HTCD = b.STKF_HTCD
					AND a.STKF_SCD = b.STKF_SCD
					AND a.STKF_STR = b.STKF_STR
					AND a.STKF_END = b.STKF_END
				LEFT OUTER JOIN #wt_UPDATE_WITH_TYUMON_KNR_MST_101 c
				ON a.STKF_KCD = c.STKF_KCD
					AND a.STKF_HTCD = c.STKF_HTCD
					AND a.STKF_SCD = c.STKF_SCD
					AND a.STKF_STR = c.STKF_STR
					AND a.STKF_END = c.STKF_END
					AND a.STKF_TEKIYOYMD = c.STKF_TEKIYOYMD
				WHERE c.STKF_KCD IS NULL
			)
		INSERT INTO #wt_UPDATE_WITH_TYUMON_KNR_MST_101
		SELECT *, dbo.CONVERT_HTCD(STKF_KCD, STKF_HTCD) AS TENCD
		FROM t1;

		DROP TABLE #wt_UPDATE_WITH_TYUMON_KNR_MST_101_1;

		/* 現状において、保留は発生しない
		-- 保留レコードを登録対象に含める ->
		WITH
			t2 AS (
				SELECT *
				FROM UPDATE_PENDING
				WHERE UDP_TBL = N'TYUMON_KNR_MST'
			)
		INSERT INTO #wt_UPDATE_WITH_TYUMON_KNR_MST_101
		SELECT t1.*, t2.UDP_TENCD
		FROM TYUMON_KNR_MST_now t1
		INNER JOIN t2
		ON t1.STKF_KCD = t2.UDP_KCD
			AND t1.STKF_HTCD = t2.UDP_HTCD
			AND t1.STKF_TEKIYOYMD = t2.UDP_TEKIYOYMD
			AND t1.STKF_UPDATECNT = t2.UDP_UPDATECNT			-- 更新されたレコードは除く
			AND t1.STKF_SCD = CAST(t2.UDP_KEY1 AS bigint)
			AND t1.STKF_STR = CAST(t2.UDP_KEY2 AS datetime)
			AND t1.STKF_END = CAST(t2.UDP_KEY3 AS datetime)
		LEFT OUTER JOIN #wt_UPDATE_WITH_TYUMON_KNR_MST_101 t3		-- 重複する場合もあるので考慮にいれる
		ON t1.STKF_KCD = t3.STKF_KCD
			AND t1.STKF_HTCD = t3.STKF_HTCD
			AND t1.STKF_TEKIYOYMD = t3.STKF_TEKIYOYMD
			AND t1.STKF_SCD = t3.STKF_SCD
			AND t1.STKF_STR = t3.STKF_STR
			AND t1.STKF_END = t3.STKF_END
		WHERE t3.STKF_KCD IS NULL;

		DELETE FROM UPDATE_PENDING
		WHERE UDP_TBL = N'TYUMON_KNR_MST';
		-- <- 保留レコードを登録対象に含める
		*/

		DELETE a
		FROM TYUMON_KNR_F_now a
		INNER JOIN #wt_UPDATE_WITH_TYUMON_KNR_MST_101 b
		ON a.TKF_HTCD = b.TENCD
			AND a.TKF_SCD = b.STKF_SCD
			AND a.TKF_STR = b.STKF_STR
			AND a.TKF_END = b.STKF_END
			AND a.TKF_TEKIYOYMD = b.STKF_TEKIYOYMD;

		INSERT INTO TYUMON_KNR_F_now
		SELECT
			TENCD,
			STKF_SCD,
			STKF_STR,
			STKF_END,
			STKF_TEKIYOYMD,
			STKF_UPDATECNT,
			STKF_SOURYO,
			0,
			STKF_SESSIONID,
			STKF_DELFG,
			STKF_INYMD,
			STKF_INTANTO,
			STKF_KOSINYMD,
			STKF_KOSINTANTO
		FROM #wt_UPDATE_WITH_TYUMON_KNR_MST_101
		WHERE STKF_DELFG <> 1;

		-- 不要レコード削除（適用日）
		DELETE a
		FROM TYUMON_KNR_F_now a
		LEFT OUTER JOIN ft_TYUMON_KNR_F(@delYmd) b
		ON a.TKF_HTCD = b.TKF_HTCD
			AND a.TKF_SCD = b.TKF_SCD
			AND a.TKF_STR = b.TKF_STR
			AND a.TKF_END = b.TKF_END
		WHERE a.TKF_TEKIYOYMD < b.TKF_TEKIYOYMD
			OR (b.TKF_TEKIYOYMD IS NULL AND a.TKF_TEKIYOYMD <= @delYmd);

		-- 不要レコード削除（終了日）	※ [TKF_END] はプライマリーキーに含まれるので、プライマリーキー単位での削除となる
		DELETE FROM TYUMON_KNR_F_now
		WHERE TKF_END < @delYmd;

		-- テーブル TYUMON_KNR_F の更新（日替わりの一回目は TRUNCATE を行い、全レコードを再作成する） ->
		DECLARE @propName_app sysname = N'UPDATE_WITH_TYUMON_KNR_MST__Truncate_DateTime';
		DECLARE @truncDt datetime;

		SELECT @truncDt = CAST(value AS datetime)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[TYUMON_KNR_F]')
			AND name = @propName_app;

		IF @truncDt IS NULL
		BEGIN
			SET @truncDt = DATEADD(day, -1, @nowDt);

			EXEC sys.sp_addextendedproperty @name = @propName_app,
				@value = @truncDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'TYUMON_KNR_F';
		END;

		IF CAST(@truncDt AS date) < @nowYmd
		BEGIN
			SELECT 
				TKF_HTCD,
				TKF_SCD,
				TKF_STR,
				TKF_END,
				TKF_NOWSURYO
			INTO #wt_UPDATE_WITH_TYUMON_KNR_MST_201
			FROM TYUMON_KNR_F;

			TRUNCATE TABLE TYUMON_KNR_F;

			INSERT INTO TYUMON_KNR_F
			SELECT
				a.TKF_HTCD,
				a.TKF_SCD,
				a.TKF_STR,
				a.TKF_END,
				a.TKF_SOURYO,
				ISNULL(b.TKF_NOWSURYO, 0),
				a.TKF_SESSIONID,
				a.TKF_INYMD,
				a.TKF_KOSINYMD,
				a.TKF_KOSINYMD
			FROM ft_TYUMON_KNR_F(@tekiYmd) a
			LEFT OUTER JOIN #wt_UPDATE_WITH_TYUMON_KNR_MST_201 b
			ON a.TKF_HTCD = b.TKF_HTCD
				AND a.TKF_SCD = b.TKF_SCD
				AND a.TKF_STR = b.TKF_STR
				AND a.TKF_END = b.TKF_END;

			DROP TABLE #wt_UPDATE_WITH_TYUMON_KNR_MST_201;

			EXEC sys.sp_updateextendedproperty @name = @propName_app,
				@value = @nowDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'TYUMON_KNR_F';
		END;
		ELSE
		BEGIN
			SELECT DISTINCT
				TENCD,
				STKF_SCD,
				STKF_STR,
				STKF_END
			INTO #wt_UPDATE_WITH_TYUMON_KNR_MST_102
			FROM #wt_UPDATE_WITH_TYUMON_KNR_MST_101;

			SELECT
				a.TENCD,
				a.STKF_SCD,
				a.STKF_STR,
				a.STKF_END,
				ISNULL(b.TKF_NOWSURYO, 0) AS TKF_NOWSURYO
			INTO #wt_UPDATE_WITH_TYUMON_KNR_MST_202
			FROM #wt_UPDATE_WITH_TYUMON_KNR_MST_102 a
			LEFT OUTER JOIN TYUMON_KNR_F b
			ON a.TENCD = b.TKF_HTCD
				AND a.STKF_SCD = b.TKF_SCD
				AND a.STKF_STR = b.TKF_STR
				AND a.STKF_END = b.TKF_END;

			DELETE a
			FROM TYUMON_KNR_F a
			INNER JOIN #wt_UPDATE_WITH_TYUMON_KNR_MST_102 b
			ON a.TKF_HTCD = b.TENCD
				AND a.TKF_SCD = b.STKF_SCD
				AND a.TKF_STR = b.STKF_STR
				AND a.TKF_END = b.STKF_END;

			DROP TABLE #wt_UPDATE_WITH_TYUMON_KNR_MST_102;

			INSERT INTO TYUMON_KNR_F
			SELECT
				a.TKF_HTCD,
				a.TKF_SCD,
				a.TKF_STR,
				a.TKF_END,
				a.TKF_SOURYO,
				b.TKF_NOWSURYO,
				a.TKF_SESSIONID,
				a.TKF_INYMD,
				a.TKF_KOSINYMD,
				a.TKF_KOSINYMD
			FROM ft_TYUMON_KNR_F(@tekiYmd) a
			INNER JOIN #wt_UPDATE_WITH_TYUMON_KNR_MST_202 b
			ON a.TKF_HTCD = b.TENCD
				AND a.TKF_SCD = b.STKF_SCD
				AND a.TKF_STR = b.STKF_STR
				AND a.TKF_END = b.STKF_END;

			DROP TABLE #wt_UPDATE_WITH_TYUMON_KNR_MST_202;
		END;
		-- <- テーブル TYUMON_KNR_F の更新（日替わりの一回目は、TRUNCATE を行い、全レコードを再作成する）

		DROP TABLE #wt_UPDATE_WITH_TYUMON_KNR_MST_101;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0
			ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_UPDATE_WITH_TYUMON_KNR_MST;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH
END
GO
