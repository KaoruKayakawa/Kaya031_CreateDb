USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CLEAR_BASEDB_DATA]') AND type in (N'P'))
DROP PROCEDURE [dbo].[CLEAR_BASEDB_DATA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: CLEAR_BASEDB_DATA
-- 機能			: 定期ジョブで BASE DB マスタから設定されるデータをクリアする。BASE DB データの初期化再設定に用いる。
--					: テーブル …_M の TRUNCATE は行わない。TYUMON_KNR_F の TKF_NOWSURYO が廃棄される。TRUNCATE は、定期ジョブ 1 回目で行われる。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2022/03/02 作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[CLEAR_BASEDB_DATA]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_CLEAR_BASEDB_DATA;
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
		DECLARE @cnt int;

		-- 不用意な誤実行を防止する。本ストアドプロシージャ実行前に、一時テーブル #CLEAR_BASEDB_DATA を作成しておく必要がある。
		SELECT @cnt = COUNT(*)
		FROM #CLEAR_BASEDB_DATA;
		DROP TABLE #CLEAR_BASEDB_DATA;

		DECLARE @db_opeEnv varchar(256);
		SELECT @db_opeEnv = ASTM_SETVALUE FROM APP_SETTING_M WHERE ASTM_SETKBN = 'DatabaseOperatingEnvironment' AND ASTM_SETDTLKBN ='X';

		IF @db_opeEnv IS NULL
		BEGIN
			SET @ErrMessage = N'テーブル [APP_SETTING_M] に "DatabaseOperatingEnvironment" の設定が見つかりません。';
			SET @ErrSeverity = 11;
			SET @ErrState = 1;

			RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
		END

		DECLARE @propName_base sysname, @propName_app sysname;

		-- APP_CATSHN
		SET @propName_base = N'UPDATE_WITH_APP_CATSHN_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		SET @propName_app = N'UPDATE_WITH_APP_CATSHN_MST__Truncate_DateTime';

		TRUNCATE TABLE APP_CATSHN_M_now;
		--TRUNCATE TABLE APP_CATSHN_M;
		
		SELECT @cnt = COUNT(*)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'APP_CATSHN_MST_now'
			AND [name] = @propName_base;

		IF @cnt > 0
			EXEC #{-BASE_DB-}#.sys.sp_dropextendedproperty @name = @propName_base,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'APP_CATSHN_MST_now';

		SELECT @cnt = COUNT(*)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[APP_CATSHN_M]')
			AND name = @propName_app;

		IF @cnt > 0
			EXEC sys.sp_dropextendedproperty @name = @propName_app,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'APP_CATSHN_M';
				
		-- KAKAKU
		SET @propName_base = N'UPDATE_WITH_KAKAKU_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		SET @propName_app = N'UPDATE_WITH_KAKAKU_MST__Truncate_DateTime';

		TRUNCATE TABLE KAKAKU_M_now;
		--TRUNCATE TABLE KAKAKU_M;
		
		SELECT @cnt = COUNT(*)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'KAKAKU_MST_now'
			AND [name] = @propName_base;

		IF @cnt > 0
			EXEC #{-BASE_DB-}#.sys.sp_dropextendedproperty @name = @propName_base,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'KAKAKU_MST_now';

		SELECT @cnt = COUNT(*)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[KAKAKU_M]')
			AND name = @propName_app;

		IF @cnt > 0
			EXEC sys.sp_dropextendedproperty @name = @propName_app,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'KAKAKU_M';
				
		-- MIXMATCH
		SET @propName_base = N'UPDATE_WITH_MIXMATCHGRP_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		SET @propName_app = N'UPDATE_WITH_MIXMATCHGRP_MST__Truncate_DateTime';

		TRUNCATE TABLE MIXMATCHGRP_M_now;
		--TRUNCATE TABLE MIXMATCHGRP_M;
		TRUNCATE TABLE MIXMATCH_M_now;
		--TRUNCATE TABLE MIXMATCH_M;
		
		SELECT @cnt = COUNT(*)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'MIXMATCHGRP_MST_now'
			AND [name] = @propName_base;

		IF @cnt > 0
			EXEC #{-BASE_DB-}#.sys.sp_dropextendedproperty @name = @propName_base,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'MIXMATCHGRP_MST_now';

		SELECT @cnt = COUNT(*)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[MIXMATCHGRP_M]')
			AND name = @propName_app;

		IF @cnt > 0
			EXEC sys.sp_dropextendedproperty @name = @propName_app,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'MIXMATCHGRP_M';
				
		-- SHOHIN
		SET @propName_base = N'UPDATE_WITH_SHOHIN_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		SET @propName_app = N'UPDATE_WITH_SHOHIN_MST__Truncate_DateTime';

		TRUNCATE TABLE SHOHIN_M_now;
		--TRUNCATE TABLE SHOHIN_M;
		TRUNCATE TABLE SHOHIN_SHOSAI_M_now;
		--TRUNCATE TABLE SHOHIN_SHOSAI_M;
		
		SELECT @cnt = COUNT(*)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'SHOHIN_MST_now'
			AND [name] = @propName_base;

		IF @cnt > 0
			EXEC #{-BASE_DB-}#.sys.sp_dropextendedproperty @name = @propName_base,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'SHOHIN_MST_now';

		SELECT @cnt = COUNT(*)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[SHOHIN_M]')
			AND name = @propName_app;

		IF @cnt > 0
			EXEC sys.sp_dropextendedproperty @name = @propName_app,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'SHOHIN_M';
				
		-- TYUMON_KNR
		SET @propName_base = N'UPDATE_WITH_TYUMON_KNR_MST__LastExecution_DateTime';
		IF @db_opeEnv = 'verify'
			SET @propName_base = @propName_base + N'__VERIFY';
		SET @propName_app = N'UPDATE_WITH_TYUMON_KNR_MST__Truncate_DateTime';

		TRUNCATE TABLE TYUMON_KNR_F_now;
		--TRUNCATE TABLE TYUMON_KNR_F;
		
		SELECT @cnt = COUNT(*)
		FROM BASE_TBL_EXPROP
		WHERE [tbl_name] = N'TYUMON_KNR_MST_now'
			AND [name] = @propName_base;

		IF @cnt > 0
			EXEC #{-BASE_DB-}#.sys.sp_dropextendedproperty @name = @propName_base,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'TYUMON_KNR_MST_now';

		SELECT @cnt = COUNT(*)
		FROM sys.extended_properties
		WHERE class= 1
			AND major_id = OBJECT_ID(N'[dbo].[TYUMON_KNR_F]')
			AND name = @propName_app;

		IF @cnt > 0
			EXEC sys.sp_dropextendedproperty @name = @propName_app,
				@level0type = 'SCHEMA',
				@level0name = N'dbo',
				@level1type = 'TABLE',
				@level1name = N'TYUMON_KNR_F';
		
		-- 保留データ
		TRUNCATE TABLE UPDATE_PENDING;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0
			ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_CLEAR_BASEDB_DATA;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH
END
GO
