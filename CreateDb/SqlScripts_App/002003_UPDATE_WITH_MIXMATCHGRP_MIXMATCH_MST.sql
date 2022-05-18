USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_WITH_MIXMATCHGRP_MIXMATCH_MST]') AND type in (N'P'))
DROP PROCEDURE [dbo].[UPDATE_WITH_MIXMATCHGRP_MIXMATCH_MST]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_WITH_MIXMATCHGRP_MST]') AND type in (N'P'))
DROP PROCEDURE [dbo].[UPDATE_WITH_MIXMATCHGRP_MST]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_WITH_MIXMATCH_MST]') AND type in (N'P'))
DROP PROCEDURE [dbo].[UPDATE_WITH_MIXMATCH_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: UPDATE_WITH_MIXMATCHGRP_MIXMATCH_MST
-- 機能			: BASE DB MIXMATCHGRP_MST_now・MIXMATCH_MST_now の内容を JYUCYU DB に反映する。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2022/02/21  作成者 : 茅川
--					: 2022/05/09　茅川
-- ====================================================
CREATE PROCEDURE [dbo].[UPDATE_WITH_MIXMATCHGRP_MIXMATCH_MST]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_UPDATE_WITH_MIXMATCHGRP_MST;
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

		DECLARE @propName_base sysname = N'UPDATE_WITH_MIXMATCHGRP_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		DECLARE @lastExeDt1 datetime, @lastExeDt2 datetime;

		SELECT @lastExeDt1 = CAST(value AS datetime)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'MIXMATCHGRP_MST_now'
			AND [name] = @propName_base;

		IF @lastExeDt1 IS NULL
		BEGIN
			SET @lastExeDt2 = @nowDt;

			EXEC #{-BASE_DB-}#.sys.sp_addextendedproperty @name = @propName_base,
				@value = @lastExeDt2,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'MIXMATCHGRP_MST_now';

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
				@level1name = N'MIXMATCHGRP_MST_now';
		END;
		
		-- MIXMATCHGRP_M_now 更新 ->
		SELECT *, dbo.CONVERT_HTCD(SMGM_KCD, SMGM_HTCD) AS TENCD
		INTO #wt_UPDATE_WITH_MIXMATCHGRP_MST_101
		FROM MIXMATCHGRP_MST_now_ZEIRITUKBN
		WHERE SMGM_KOSINYMD > @lastExeDt1;
		
		-- 新規レコードの [適用日] 以外のプライマリキーが一致するレコードを、更新対象に含める。
		-- ※ 本プロシージャでの削除処理を、正しく行うために必要。
		SELECT DISTINCT SMGM_KCD, SMGM_HTCD, SMGM_MMNO
		INTO #wt_UPDATE_WITH_MIXMATCHGRP_MST_101_1
		FROM #wt_UPDATE_WITH_MIXMATCHGRP_MST_101;

		WITH
			t1 AS (
				SELECT a.*
				FROM MIXMATCHGRP_MST_now_ZEIRITUKBN a
				INNER JOIN #wt_UPDATE_WITH_MIXMATCHGRP_MST_101_1 b
				ON a.SMGM_KCD = b.SMGM_KCD
					AND a.SMGM_HTCD = b.SMGM_HTCD
					AND a.SMGM_MMNO = b.SMGM_MMNO
				LEFT OUTER JOIN #wt_UPDATE_WITH_MIXMATCHGRP_MST_101 c
				ON a.SMGM_KCD = c.SMGM_KCD
					AND a.SMGM_HTCD = c.SMGM_HTCD
					AND a.SMGM_MMNO = c.SMGM_MMNO
					AND a.SMGM_TEKIYOYMD = c.SMGM_TEKIYOYMD
				WHERE c.SMGM_KCD IS NULL
			)
		INSERT INTO #wt_UPDATE_WITH_MIXMATCHGRP_MST_101
		SELECT *, dbo.CONVERT_HTCD(SMGM_KCD, SMGM_HTCD) AS TENCD
		FROM t1;

		DROP TABLE #wt_UPDATE_WITH_MIXMATCHGRP_MST_101_1;

		-- 保留レコードを登録対象に含める ->
		WITH
			t2 AS (
				SELECT *
				FROM UPDATE_PENDING
				WHERE UDP_TBL = N'MIXMATCHGRP_MST'
			)
		INSERT INTO #wt_UPDATE_WITH_MIXMATCHGRP_MST_101
		SELECT t1.*, t2.UDP_TENCD
		FROM MIXMATCHGRP_MST_now_ZEIRITUKBN t1
		INNER JOIN t2
		ON t1.SMGM_KCD = t2.UDP_KCD
			AND t1.SMGM_HTCD = t2.UDP_HTCD
			AND t1.SMGM_TEKIYOYMD = t2.UDP_TEKIYOYMD
			AND t1.SMGM_UPDATECNT = t2.UDP_UPDATECNT			-- 更新されたレコードは除く
			AND t1.SMGM_MMNO = CAST(t2.UDP_KEY1 AS int)
		LEFT OUTER JOIN #wt_UPDATE_WITH_MIXMATCHGRP_MST_101 t3		-- 重複する場合もあるので考慮にいれる
		ON t1.SMGM_KCD = t3.SMGM_KCD
			AND t1.SMGM_HTCD = t3.SMGM_HTCD
			AND t1.SMGM_TEKIYOYMD = t3.SMGM_TEKIYOYMD
			AND t1.SMGM_MMNO = t3.SMGM_MMNO
		WHERE t3.SMGM_KCD IS NULL;
			
		DELETE FROM UPDATE_PENDING
		WHERE UDP_TBL = N'MIXMATCHGRP_MST';
		-- <- 保留レコードを登録対象に含める

		-- 保留レコード登録
		INSERT INTO UPDATE_PENDING (
			UDP_TBL,
			UDP_KCD,
			UDP_HTCD,
			UDP_TEKIYOYMD,
			UDP_UPDATECNT,
			UDP_KEY1,
			UDP_NOTE,
			UDP_TENCD
		)
		SELECT N'MIXMATCHGRP_MST',
			SMGM_KCD,
			SMGM_HTCD,
			SMGM_TEKIYOYMD,
			SMGM_UPDATECNT,
			SMGM_MMNO,
			N'[ミックスマッチ商品] 未登録（MIXMATCH_MST_now・SHOHIN_MST_now）',
			TENCD
		FROM #wt_UPDATE_WITH_MIXMATCHGRP_MST_101
		WHERE SMGM_DELFG = 0
			AND SSHM_ZEIRITUKBN IS NULL;

		-- 登録対象から保留レコードを削除
		DELETE FROM #wt_UPDATE_WITH_MIXMATCHGRP_MST_101
		WHERE SMGM_DELFG = 0
			AND SSHM_ZEIRITUKBN IS NULL;

		DELETE a
		FROM MIXMATCHGRP_M_now a
		INNER JOIN #wt_UPDATE_WITH_MIXMATCHGRP_MST_101 b
		ON a.MGM_HTCD = b.TENCD
			AND a.MGM_MMNO = b.SMGM_MMNO
			AND a.MGM_TEKIYOYMD = b.SMGM_TEKIYOYMD;

		INSERT INTO MIXMATCHGRP_M_now
		SELECT
			TENCD,
			SMGM_MMNO,
			SMGM_TEKIYOYMD,
			SMGM_UPDATECNT,
			ISNULL(SMGM_MMNAME, ' '),
			ISNULL(SMGM_MMSTR, CAST('1753-1-1' AS datetime)),
			ISNULL(SMGM_MMEND, CAST('1753-1-1' AS datetime)),
			SMGM_SETKOSU1,
			SMGM_SETKINGAKU1,
			SSHM_ZEIRITUKBN,
			SMGM_DELFG,
			SMGM_INYMD,
			SMGM_INTANTO,
			SMGM_KOSINYMD,
			SMGM_KOSINTANTO
		FROM #wt_UPDATE_WITH_MIXMATCHGRP_MST_101
		WHERE SMGM_DELFG <> 1;
		-- <- MIXMATCHGRP_M_now 更新

		--  MIXMATCH_M_now 更新 ->
		SELECT *, dbo.CONVERT_HTCD(SMIM_KCD, SMIM_HTCD) AS TENCD
		INTO #wt_UPDATE_WITH_MIXMATCH_MST_101
		FROM MIXMATCH_MST_now
		WHERE SMIM_KOSINYMD > @lastExeDt1;
		
		-- 新規レコードの [適用日] 以外のプライマリキーが一致するレコードを、更新対象に含める。
		-- ※ 本プロシージャでの削除処理を、正しく行うために必要。
		SELECT DISTINCT SMIM_KCD, SMIM_HTCD, SMIM_MMNO, SMIM_SCD
		INTO #wt_UPDATE_WITH_MIXMATCH_MST_101_1
		FROM #wt_UPDATE_WITH_MIXMATCH_MST_101;

		WITH
			t1 AS (
				SELECT a.*
				FROM MIXMATCH_MST_now a
				INNER JOIN #wt_UPDATE_WITH_MIXMATCH_MST_101_1 b
				ON a.SMIM_KCD = b.SMIM_KCD
					AND a.SMIM_HTCD = b.SMIM_HTCD
					AND a.SMIM_MMNO = b.SMIM_MMNO
					AND a.SMIM_SCD = b.SMIM_SCD
				LEFT OUTER JOIN #wt_UPDATE_WITH_MIXMATCH_MST_101 c
				ON a.SMIM_KCD = c.SMIM_KCD
					AND a.SMIM_HTCD = c.SMIM_HTCD
					AND a.SMIM_MMNO = c.SMIM_MMNO
					AND a.SMIM_SCD = c.SMIM_SCD
					AND a.SMIM_TEKIYOYMD = c.SMIM_TEKIYOYMD
				WHERE c.SMIM_KCD IS NULL
			)
		INSERT INTO #wt_UPDATE_WITH_MIXMATCH_MST_101
		SELECT *, dbo.CONVERT_HTCD(SMIM_KCD, SMIM_HTCD) AS TENCD
		FROM t1;

		DROP TABLE #wt_UPDATE_WITH_MIXMATCH_MST_101_1;

		-- 保留レコードを登録対象に含める ->
		WITH
			t2 AS (
				SELECT *
				FROM UPDATE_PENDING
				WHERE UDP_TBL = N'MIXMATCH_MST'
			)
		INSERT INTO #wt_UPDATE_WITH_MIXMATCH_MST_101
		SELECT t1.*, t2.UDP_TENCD
		FROM MIXMATCH_MST_now t1
		INNER JOIN t2
		ON t1.SMIM_KCD = t2.UDP_KCD
			AND t1.SMIM_HTCD = t2.UDP_HTCD
			AND t1.SMIM_TEKIYOYMD = t2.UDP_TEKIYOYMD
			AND t1.SMIM_UPDATECNT = t2.UDP_UPDATECNT			-- 更新されたレコードは除く
			AND t1.SMIM_MMNO = CAST(t2.UDP_KEY1 AS int)
			AND t1.SMIM_SCD = CAST(t2.UDP_KEY2 AS bigint)
		LEFT OUTER JOIN #wt_UPDATE_WITH_MIXMATCH_MST_101 t3		-- 重複する場合もあるので考慮にいれる
		ON t1.SMIM_KCD = t3.SMIM_KCD
			AND t1.SMIM_HTCD = t3.SMIM_HTCD
			AND t1.SMIM_TEKIYOYMD = t3.SMIM_TEKIYOYMD
			AND t1.SMIM_MMNO = t3.SMIM_MMNO
			AND t1.SMIM_SCD = t3.SMIM_SCD
		WHERE t3.SMIM_KCD IS NULL;
		
		DELETE FROM UPDATE_PENDING
		WHERE UDP_TBL = N'MIXMATCH_MST';
		-- <- 保留レコードを登録対象に含める

		-- 保留レコード登録
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
		SELECT N'MIXMATCH_MST',
			a.SMIM_KCD,
			a.SMIM_HTCD,
			a.SMIM_TEKIYOYMD,
			a.SMIM_UPDATECNT,
			a.SMIM_MMNO,
			a.SMIM_SCD,
			N'[ミックスマッチグループ] 未登録（MIXMATCH_M_now） ',
			a.TENCD
		FROM #wt_UPDATE_WITH_MIXMATCH_MST_101 a
		LEFT OUTER JOIN vi_MIXMATCHGRP_M b
		ON a.TENCD = b.MGM_HTCD
			AND a.SMIM_MMNO = b.MGM_MMNO
			AND (a.SMIM_TEKIYOYMD BETWEEN b.MGM_TEKIYOYMD AND b.MGM_TEKIYOYMD_END)
		WHERE b.MGM_HTCD IS NULL;

		-- 登録対象から保留レコードを削除 -> 後の処理で行われるので、ここでは行わない。

		DELETE a
		FROM MIXMATCH_M_now a
		INNER JOIN #wt_UPDATE_WITH_MIXMATCH_MST_101 b
		ON a.MIM_HTCD = b.TENCD
			AND a.MIM_MMNO = b.SMIM_MMNO
			AND a.MIM_SCD = b.SMIM_SCD
			AND a.MIM_TEKIYOYMD = b.SMIM_TEKIYOYMD;

		INSERT INTO MIXMATCH_M_now
		SELECT
			TENCD,
			SMIM_MMNO,
			SMIM_SCD,
			SMIM_TEKIYOYMD,
			SMIM_UPDATECNT,
			SMIM_DELFG,
			SMIM_INYMD,
			SMIM_INTANTO,
			SMIM_KOSINYMD,
			SMIM_KOSINTANTO
		FROM #wt_UPDATE_WITH_MIXMATCH_MST_101
		WHERE SMIM_DELFG <> 1;
		-- <- MIXMATCH_M_now 更新

		-- グループ、不要レコード削除（適用日）
		DELETE a
		FROM MIXMATCHGRP_M_now a
		LEFT OUTER JOIN ft_MIXMATCHGRP_M(@delYmd) b
		ON a.MGM_HTCD = b.MGM_HTCD
			AND a.MGM_MMNO = b.MGM_MMNO
		WHERE a.MGM_TEKIYOYMD < b.MGM_TEKIYOYMD
			OR (b.MGM_TEKIYOYMD IS NULL AND a.MGM_TEKIYOYMD <= @delYmd);

		-- グループ、不要レコード削除（ミックスマッチ終了日）	※ プライマリーキー単位での削除
		WITH
			t2 AS (
				SELECT MGM_HTCD, MGM_MMNO
				FROM MIXMATCHGRP_M_now
				GROUP BY MGM_HTCD, MGM_MMNO
				HAVING MAX(MGM_MMEND) < @delYmd
			)
		DELETE t1
		FROM MIXMATCHGRP_M_now t1
		INNER JOIN t2
		ON t1.MGM_HTCD = t2.MGM_HTCD
			AND t1.MGM_MMNO = t2.MGM_MMNO;

		-- 商品、不要レコード削除（ミックスマッチ番号）
		DELETE a
		FROM MIXMATCH_M_now a
		LEFT OUTER JOIN vi_MIXMATCHGRP_M b
		ON a.MIM_HTCD = b.MGM_HTCD
			AND a.MIM_MMNO = b.MGM_MMNO
			AND (a.MIM_TEKIYOYMD BETWEEN b.MGM_TEKIYOYMD AND b.MGM_TEKIYOYMD_END)
		WHERE b.MGM_HTCD IS NULL;

		-- テーブル …_M の更新（日替わりの一回目は TRUNCATE を行い、全レコードを再作成する） ->
		DECLARE @propName_app sysname = N'UPDATE_WITH_MIXMATCHGRP_MST__Truncate_DateTime';
		DECLARE @truncDt datetime;

		SELECT @truncDt = CAST(value AS datetime)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[MIXMATCHGRP_M]')
			AND name = @propName_app;

		IF @truncDt IS NULL
		BEGIN
			SET @truncDt = DATEADD(day, -1, @nowDt);

			EXEC sys.sp_addextendedproperty @name = @propName_app,
				@value = @truncDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'MIXMATCHGRP_M';
		END;

		IF CAST(@truncDt AS date) < @nowYmd
		BEGIN
			-- グループ ->
			TRUNCATE TABLE MIXMATCHGRP_M;

			INSERT INTO MIXMATCHGRP_M
			SELECT
				MGM_HTCD,
				MGM_MMNO,
				MGM_MMNAME,
				MGM_MMSTR,
				MGM_MMEND,
				MGM_SETKOSU,
				MGM_SETKINGAKU,
				MGM_TAXKBN,
				MGM_INYMD,
				MGM_KOSINYMD,
				MGM_KOSINYMD
			FROM ft_MIXMATCHGRP_M(@tekiYmd);
			-- <- グループ 

			-- 商品 ->
			TRUNCATE TABLE MIXMATCH_M;

			INSERT INTO MIXMATCH_M
			SELECT
				MIM_HTCD,
				MIM_MMNO,
				MIM_SCD,
				MIM_INYMD,
				MIM_KOSINYMD,
				MIM_KOSINYMD
			FROM ft_MIXMATCH_M(@tekiYmd);
			-- <- 商品

			EXEC sys.sp_updateextendedproperty @name = @propName_app,
				@value = @nowDt,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'MIXMATCHGRP_M';
		END;
		ELSE
		BEGIN
			-- グループ ->
			SELECT DISTINCT
				TENCD,
				SMGM_MMNO
			INTO #wt_UPDATE_WITH_MIXMATCHGRP_MST_201
			FROM #wt_UPDATE_WITH_MIXMATCHGRP_MST_101;

			DELETE a
			FROM MIXMATCHGRP_M a
			INNER JOIN #wt_UPDATE_WITH_MIXMATCHGRP_MST_201 b
			ON a.MGM_HTCD = b.TENCD
				AND a.MGM_MMNO = b.SMGM_MMNO;

			INSERT INTO MIXMATCHGRP_M
			SELECT
				a.MGM_HTCD,
				a.MGM_MMNO,
				a.MGM_MMNAME,
				a.MGM_MMSTR,
				a.MGM_MMEND,
				a.MGM_SETKOSU,
				a.MGM_SETKINGAKU,
				a.MGM_TAXKBN,
				a.MGM_INYMD,
				a.MGM_KOSINYMD,
				a.MGM_KOSINYMD
			FROM ft_MIXMATCHGRP_M(@tekiYmd) a
			INNER JOIN #wt_UPDATE_WITH_MIXMATCHGRP_MST_201 b
			ON a.MGM_HTCD = b.TENCD
				AND a.MGM_MMNO = b.SMGM_MMNO;

			DROP TABLE #wt_UPDATE_WITH_MIXMATCHGRP_MST_201;
			-- <- グループ

			-- 商品 ->
			SELECT DISTINCT
				TENCD,
				SMIM_MMNO,
				SMIM_SCD
			INTO #wt_UPDATE_WITH_MIXMATCH_MST_201
			FROM #wt_UPDATE_WITH_MIXMATCH_MST_101;

			DELETE a
			FROM MIXMATCH_M a
			INNER JOIN #wt_UPDATE_WITH_MIXMATCH_MST_201 b
			ON a.MIM_HTCD = b.TENCD
				AND a.MIM_MMNO = b.SMIM_MMNO
				AND a.MIM_SCD = b.SMIM_SCD;
				
			INSERT INTO MIXMATCH_M
			SELECT
				a.MIM_HTCD,
				a.MIM_MMNO,
				a.MIM_SCD,
				a.MIM_INYMD,
				a.MIM_KOSINYMD,
				a.MIM_KOSINYMD
			FROM ft_MIXMATCH_M(@tekiYmd) a
			INNER JOIN #wt_UPDATE_WITH_MIXMATCH_MST_201 b
			ON a.MIM_HTCD = b.TENCD
				AND a.MIM_MMNO = b.SMIM_MMNO
				AND a.MIM_SCD = b.SMIM_SCD;

			DROP TABLE #wt_UPDATE_WITH_MIXMATCH_MST_201;
			-- <- 商品
		END;
		-- <- テーブル …_M の更新（日替わりの一回目は TRUNCATE を行い、全レコードを再作成する）

		DROP TABLE #wt_UPDATE_WITH_MIXMATCHGRP_MST_101;
		DROP TABLE #wt_UPDATE_WITH_MIXMATCH_MST_101;

		-- グループ、不要レコード削除（ミックスマッチ終了日）	※ プライマリーキー単位削除が行われなかったレコード
		DELETE FROM MIXMATCHGRP_M
		WHERE MGM_MMEND < @delYmd;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0
			ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_UPDATE_WITH_MIXMATCHGRP_MST;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH
END
GO
