USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_WITH_APP_CATSHN_MST]') AND type in (N'P'))
DROP PROCEDURE [dbo].[UPDATE_WITH_APP_CATSHN_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: UPDATE_WITH_APP_CATSHN_MST
-- 機能			: BASE DB APP_CATSHN_MST_now の内容を、JYUCYU DB APP_CATSHN_M_now・APP_CATSHN_M に反映する。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/07/12  作成者 : 茅川
-- 更新			: 2021/10/19　茅川
--					: 2021/12/08　茅川
--					: 2022/01/31　茅川
--					: 2022/02/01　茅川
--					: 2022/02/25　茅川
-- ====================================================
CREATE PROCEDURE [dbo].[UPDATE_WITH_APP_CATSHN_MST]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_UPDATE_WITH_APP_CATSHN_MST;
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

		DECLARE @propName_base sysname = N'UPDATE_WITH_APP_CATSHN_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		DECLARE @lastExeDt1 datetime, @lastExeDt2 datetime;

		SELECT @lastExeDt1 = CAST(value AS datetime)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'APP_CATSHN_MST_now'
			AND [name] = @propName_base;

		IF @lastExeDt1 IS NULL
		BEGIN
			SET @lastExeDt2 = @nowDt;

			EXEC #{-BASE_DB-}#.sys.sp_addextendedproperty @name = @propName_base,
				@value = @lastExeDt2,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'APP_CATSHN_MST_now';

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
				@level1name = N'APP_CATSHN_MST_now';
		END;

		SELECT *, dbo.CONVERT_HTCD(SCSM_KCD, SCSM_HTCD) AS TENCD
		INTO #wt_UPDATE_WITH_APP_CATSHN_MST_101
		FROM APP_CATSHN_MST_now
		WHERE SCSM_KOSINYMD > @lastExeDt1;
		
		-- 新規レコードの [適用日] 以外のプライマリキーが一致するレコードを、更新対象に含める。
		-- ※ 本プロシージャでの削除処理を、正しく行うために必要。
		WITH
			t1 AS (
				SELECT DISTINCT SCSM_KCD, SCSM_HTCD, SCSM_LCATCD, SCSM_MCATCD, SCSM_SCATCD, SCSM_SCD
				FROM #wt_UPDATE_WITH_APP_CATSHN_MST_101
			),
			t2 AS (
				SELECT a.*
				FROM APP_CATSHN_MST_now a
				INNER JOIN t1
				ON a.SCSM_KCD = t1.SCSM_KCD
					AND a.SCSM_HTCD = t1.SCSM_HTCD
					AND a.SCSM_LCATCD = t1.SCSM_LCATCD
					AND a.SCSM_MCATCD = t1.SCSM_MCATCD
					AND a.SCSM_SCATCD = t1.SCSM_SCATCD
					AND a.SCSM_SCD = t1.SCSM_SCD
				LEFT OUTER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_101 b
				ON a.SCSM_KCD = b.SCSM_KCD
					AND a.SCSM_HTCD = b.SCSM_HTCD
					AND a.SCSM_LCATCD = b.SCSM_LCATCD
					AND a.SCSM_MCATCD = b.SCSM_MCATCD
					AND a.SCSM_SCATCD = b.SCSM_SCATCD
					AND a.SCSM_SCD = b.SCSM_SCD
					AND a.SCSM_TEKIYOYMD = b.SCSM_TEKIYOYMD
				WHERE b.SCSM_KCD IS NULL
			)
		INSERT INTO #wt_UPDATE_WITH_APP_CATSHN_MST_101
		SELECT *, dbo.CONVERT_HTCD(SCSM_KCD, SCSM_HTCD) AS TENCD
		FROM t2;

		/* 現状において、保留は発生しない
		-- 保留レコードを登録対象に含める ->
		WITH
			t2 AS (
				SELECT *
				FROM UPDATE_PENDING
				WHERE UDP_TBL = N'APP_CATSHN_MST'
			)
		INSERT INTO #wt_UPDATE_WITH_APP_CATSHN_MST_101
		SELECT t1.*, t2.UDP_TENCD
		FROM APP_CATSHN_MST_now t1
		INNER JOIN t2
		ON t1.SCSM_KCD = t2.UDP_KCD
			AND t1.SCSM_HTCD = t2.UDP_HTCD
			AND t1.SCSM_TEKIYOYMD = t2.UDP_TEKIYOYMD
			AND t1.SCSM_UPDATECNT = t2.UDP_UPDATECNT			-- 更新されたレコードは除く
			AND t1.SCSM_LCATCD = CAST(t2.UDP_KEY1 AS char(4))
			AND t1.SCSM_MCATCD = CAST(t2.UDP_KEY2 AS char(4))
			AND t1.SCSM_SCATCD = CAST(t2.UDP_KEY3 AS char(4))
			AND t1.SCSM_SCD = CAST(t2.UDP_KEY4 AS bigint)
		LEFT OUTER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_101 t3		-- 重複する場合もあるので考慮にいれる
		ON t1.SCSM_KCD = t3.SCSM_KCD
			AND t1.SCSM_HTCD = t3.SCSM_HTCD
			AND t1.SCSM_TEKIYOYMD = t3.SCSM_TEKIYOYMD
			AND t1.SCSM_LCATCD = t3.SCSM_LCATCD
			AND t1.SCSM_MCATCD = t3.SCSM_MCATCD
			AND t1.SCSM_SCATCD = t3.SCSM_SCATCD
			AND t1.SCSM_SCD = t3.SCSM_SCD
		WHERE t3.SCSM_KCD IS NULL;
			
		DELETE FROM UPDATE_PENDING
		WHERE UDP_TBL = N'APP_CATSHN_MST';
		-- <- 保留レコードを登録対象に含める
		*/

		DELETE a
		FROM APP_CATSHN_M_now a
		INNER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_101 b
		ON a.ACSM_HTCD = b.TENCD
			AND a.ACSM_LCATCD = b.SCSM_LCATCD
			AND a.ACSM_MCATCD = b.SCSM_MCATCD
			AND a.ACSM_SCATCD = b.SCSM_SCATCD
			AND a.ACSM_SCD = b.SCSM_SCD
			AND a.ACSM_TEKIYOYMD = b.SCSM_TEKIYOYMD;

		INSERT INTO APP_CATSHN_M_now
		SELECT
			TENCD,
			SCSM_LCATCD,
			SCSM_MCATCD,
			SCSM_SCATCD,
			SCSM_SCD,
			SCSM_TEKIYOYMD,
			SCSM_UPDATECNT,
			SCSM_APPKEISAIJYUN,
			SCSM_DELFG,
			SCSM_INYMD,
			SCSM_INTANTO,
			SCSM_KOSINYMD,
			SCSM_KOSINTANTO
		FROM #wt_UPDATE_WITH_APP_CATSHN_MST_101
		WHERE SCSM_DELFG <> 1;

		-- 不要レコード削除（適用日）
		DELETE a
		FROM APP_CATSHN_M_now a
		LEFT OUTER JOIN ft_APP_CATSHN_M(@delYmd) b
		ON a.ACSM_HTCD = b.ACSM_HTCD
			AND a.ACSM_LCATCD = b.ACSM_LCATCD
			AND a.ACSM_MCATCD = b.ACSM_MCATCD
			AND a.ACSM_SCATCD = b.ACSM_SCATCD
			AND a.ACSM_SCD = b.ACSM_SCD
		WHERE a.ACSM_TEKIYOYMD < b.ACSM_TEKIYOYMD
			OR (b.ACSM_TEKIYOYMD IS NULL AND a.ACSM_TEKIYOYMD <= @delYmd);

		-- テーブル APP_CATSHN_M の更新（日替わりの一回目は TRUNCATE を行い、全レコードを再作成する） ->
		DECLARE @propName_app sysname = N'UPDATE_WITH_APP_CATSHN_MST__Truncate_DateTime';
		DECLARE @truncDt datetime;

		SELECT @truncDt = CAST(value AS datetime)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[APP_CATSHN_M]')
			AND name = @propName_app;

		IF @truncDt IS NULL
		BEGIN
			SET @truncDt = DATEADD(day, -1, @nowDt);

			EXEC sys.sp_addextendedproperty @name = @propName_app,
				@value = @truncDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'APP_CATSHN_M';
		END;

		IF CAST(@truncDt AS date) < @nowYmd
		BEGIN
			TRUNCATE TABLE APP_CATSHN_M;

			INSERT INTO APP_CATSHN_M
			SELECT
				ACSM_HTCD,
				ACSM_LCATCD,
				ACSM_MCATCD,
				ACSM_SCATCD,
				ACSM_SCD,
				ACSM_APPKEISAIJYUN,
				ACSM_INYMD,
				ACSM_KOSINYMD,
				0
			FROM ft_APP_CATSHN_M(@tekiYmd);

			EXEC sys.sp_updateextendedproperty @name = @propName_app,
				@value = @nowDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'APP_CATSHN_M';
		END;
		ELSE
		BEGIN
			SELECT DISTINCT
				TENCD,
				SCSM_LCATCD,
				SCSM_MCATCD,
				SCSM_SCATCD,
				SCSM_SCD
			INTO #wt_UPDATE_WITH_APP_CATSHN_MST_102
			FROM #wt_UPDATE_WITH_APP_CATSHN_MST_101;

			DELETE a
			FROM APP_CATSHN_M a
			INNER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_102 b
			ON a.ACSM_HTCD = b.TENCD
				AND a.ACSM_LCATCD = b.SCSM_LCATCD
				AND a.ACSM_MCATCD = b.SCSM_MCATCD
				AND a.ACSM_SCATCD = b.SCSM_SCATCD
				AND a.ACSM_SCD = b.SCSM_SCD;
				
			INSERT INTO APP_CATSHN_M
			SELECT
				a.ACSM_HTCD,
				a.ACSM_LCATCD,
				a.ACSM_MCATCD,
				a.ACSM_SCATCD,
				a.ACSM_SCD,
				a.ACSM_APPKEISAIJYUN,
				a.ACSM_INYMD,
				a.ACSM_KOSINYMD,
				0
			FROM ft_APP_CATSHN_M(@tekiYmd) a
			INNER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_102 b
			ON a.ACSM_HTCD = b.TENCD
				AND a.ACSM_LCATCD = b.SCSM_LCATCD
				AND a.ACSM_MCATCD = b.SCSM_MCATCD
				AND a.ACSM_SCATCD = b.SCSM_SCATCD
				AND a.ACSM_SCD = b.SCSM_SCD;

			DROP TABLE #wt_UPDATE_WITH_APP_CATSHN_MST_102;

			DELETE FROM APP_CATSHN_M
			WHERE ACSM_AUTOADDFLG = 1;
		END;
		-- <- テーブル APP_CATSHN_M の更新（日替わりの一回目は、TRUNCATE を行い、全レコードを再作成する）

		DROP TABLE #wt_UPDATE_WITH_APP_CATSHN_MST_101;
		
		-- SJ 区分による自動追加 ->
		WITH
			t1 AS (
				SELECT DISTINCT dbo.CONVERT_HTCD(SCSM_KCD, SCSM_HTCD) AS KHTCD, SCSM_LCATCD, SCSM_MCATCD, SCSM_SCATCD, SCSM_SCD
				FROM ft_APP_CATSHN_MST(@tekiYmd)
			),
			t2 AS (
				SELECT ACTM_HTCD, ACTM_LCATCD, ACTM_MCATCD, ACTM_SCATCD, ACTM_CATORDER
				FROM APP_CAT_M
				WHERE ACTM_JYOGAIFLG = 0
			),
			t3 AS (
				SELECT ACTM_HTCD, ACTM_LCATCD, MAX(ACTM_CATORDER) AS ACTM_CATORDER
				FROM APP_CAT_M
				WHERE ACTM_MCATCD = '0000'
				GROUP BY ACTM_HTCD, ACTM_LCATCD
			)
		SELECT t1.KHTCD, t1.SCSM_LCATCD, t1.SCSM_SCD,
			MAX(t3.ACTM_CATORDER) AS LORDER, MAX(t2.ACTM_CATORDER) AS MORDER
		INTO #wt_UPDATE_WITH_APP_CATSHN_MST_201
		FROM t1
		LEFT OUTER JOIN t2
		ON t1.KHTCD = t2.ACTM_HTCD
			AND t1.SCSM_LCATCD = t2.ACTM_LCATCD
			AND t1.SCSM_MCATCD = t2.ACTM_MCATCD
			AND t1.SCSM_SCATCD = t2.ACTM_SCATCD
		LEFT OUTER JOIN t3
		ON t1.KHTCD = t3.ACTM_HTCD
			AND t1.SCSM_LCATCD = t3.ACTM_LCATCD
		GROUP BY t1.KHTCD, t1.SCSM_LCATCD, t1.SCSM_SCD;

		WITH
			t1 AS (
				SELECT DISTINCT dbo.CONVERT_HTCD(SKAK_KCD, SKAK_HTCD) AS KHTCD, SKAK_SCD, SKAK_TOKUSJKBN
				FROM ft_KAKAKU_MST(@tekiYmd)
				WHERE SKAK_TOKUEND >= DATEADD(day, -1, CAST(GETDATE() AS date))
			)
		SELECT t1.KHTCD, t1.SKAK_SCD, t1.SKAK_TOKUSJKBN,
			a.SCSM_LCATCD, a.LORDER, a.MORDER
		INTO #wt_UPDATE_WITH_APP_CATSHN_MST_202
		FROM t1
		INNER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_201 a
		ON t1.KHTCD = a.KHTCD
			AND t1.SKAK_SCD = a.SCSM_SCD;

		DROP TABLE #wt_UPDATE_WITH_APP_CATSHN_MST_201;

		WITH
			t1 AS (
				SELECT SJKBN, LCAT, MCAT, BUMON
				FROM CATSHN_INSERT_SETTING
				WHERE SJKBN <> 0
			),
			t2 AS (
				SELECT SJKBN, LCAT, MCAT, BUMON
				FROM t1
				WHERE BUMON = '0000'
			)
		SELECT SJKBN, LCAT, MCAT, BUMON
		INTO #wt_UPDATE_WITH_APP_CATSHN_MST_203
		FROM t2
		UNION
		SELECT t1.SJKBN, t1.LCAT, t1.MCAT, t1.BUMON
		FROM t1
		LEFT OUTER JOIN t2
		ON t1.SJKBN = t2.SJKBN
			AND t1.LCAT = t2.LCAT
			AND t1.MCAT = t2.MCAT
		WHERE t2.SJKBN IS NULL;

		DECLARE @insDt datetime = GETDATE();

		WITH
			t1 AS (
				SELECT a.KHTCD, b.LCAT, b.MCAT, CAST('0000' AS char(4)) AS SCAT, a.SKAK_SCD, a.LORDER, a.MORDER,
					@insDt AS INSDAT, @insDt AS UPDAT,
					ROW_NUMBER() OVER(PARTITION BY a.KHTCD, b.LCAT, b.MCAT, a.SKAK_SCD ORDER BY a.LORDER DESC, a.MORDER DESC) AS recId
				FROM #wt_UPDATE_WITH_APP_CATSHN_MST_202 a
				INNER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_203 b
				ON a.SKAK_TOKUSJKBN = b.SJKBN
					AND (a.SCSM_LCATCD = b.BUMON OR b.BUMON = '0000')
			),
			t2 AS (
				SELECT *
				FROM t1
				WHERE recId = 1
			)
		SELECT KHTCD, LCAT, MCAT, SCAT, SKAK_SCD,
			(LORDER * 100000) + (MORDER * 1000) + dbo.GET_MINKEISAIJYUN(KHTCD, SKAK_SCD) AS APPKEISAIJYUN,
			INSDAT, UPDAT
		INTO #wt_UPDATE_WITH_APP_CATSHN_MST_204
		FROM t2
		WHERE LORDER IS NOT NULL AND MORDER IS NOT NULL
		UNION ALL
		SELECT KHTCD, LCAT, MCAT, SCAT, SKAK_SCD,
			888888888 AS APPKEISAIJYUN,
			INSDAT, UPDAT
		FROM t2
		WHERE LORDER IS NULL OR MORDER IS NULL;

		DROP TABLE #wt_UPDATE_WITH_APP_CATSHN_MST_202;
		DROP TABLE #wt_UPDATE_WITH_APP_CATSHN_MST_203;

		DELETE a
		FROM APP_CATSHN_M a
		INNER JOIN #wt_UPDATE_WITH_APP_CATSHN_MST_204 b
		ON a.ACSM_HTCD = b.KHTCD
			AND a.ACSM_LCATCD = b.LCAT
			AND a.ACSM_MCATCD = b.MCAT
			AND a.ACSM_SCATCD = b.SCAT
			AND a.ACSM_SCD = b.SKAK_SCD;

		INSERT INTO APP_CATSHN_M
		SELECT *, 1
		FROM #wt_UPDATE_WITH_APP_CATSHN_MST_204;

		DROP TABLE #wt_UPDATE_WITH_APP_CATSHN_MST_204;
		-- <- SJ 区分による自動追加
		
		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0
			ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_UPDATE_WITH_APP_CATSHN_MST;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH
END
GO
