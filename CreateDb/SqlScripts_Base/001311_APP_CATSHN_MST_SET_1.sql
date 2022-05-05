USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APP_CATSHN_MST_SET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[APP_CATSHN_MST_SET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: APP_CATSHN_MST_SET_1
-- 機能			: テーブル APP_CATSHN_MST のレコード 1 件を登録する。
--					: SCSM_DELFG = 2 の場合は、適用日以降を無設定とする。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2022/03/07  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[APP_CATSHN_MST_SET_1]
	@SCSM_KCD int,
	@SCSM_HTCD int,
	@SCSM_LCATCD char(4),
	@SCSM_MCATCD char(4),
	@SCSM_SCATCD char(4),
	@SCSM_SCD bigint,
	@SCSM_TEKIYOYMD datetime,
	@SCSM_UPDATECNT int,
	@SCSM_CATSBT int,
	@SCSM_APPKEISAIJYUN int,
	@SCSM_YDELKBN int,
	@SCSM_MDELKBN int,
	@SCSM_YOBI1 int,
	@SCSM_YOBI2 int,
	@SCSM_YOBI3 int,
	@SCSM_YOBI4 varchar(100),
	@SCSM_YOBI5 varchar(100),
	@SCSM_YOBI6 varchar(100),
	@SCSM_YOBI7 datetime,
	@SCSM_YOBI8 datetime,
	@SCSM_YOBI9 datetime,
	@SCSM_IMPORTYMD datetime,
	@SCSM_IMPORTFILE varchar(100),
	@SCSM_DELFG tinyint,
	@SCSM_INYMD datetime,
	@SCSM_INTANTO varchar(100),
	@SCSM_KOSINYMD datetime,
	@SCSM_KOSINTANTO varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_APP_CATSHN_MST_SET_1_1;
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
		INSERT INTO APP_CATSHN_MST_now
		VALUES (
			@SCSM_KCD,
			@SCSM_HTCD,
			@SCSM_LCATCD,
			@SCSM_MCATCD,
			@SCSM_SCATCD,
			@SCSM_SCD,
			@SCSM_TEKIYOYMD,
			@SCSM_UPDATECNT,
			@SCSM_CATSBT,
			@SCSM_APPKEISAIJYUN,
			@SCSM_YDELKBN,
			@SCSM_MDELKBN,
			@SCSM_YOBI1,
			@SCSM_YOBI2,
			@SCSM_YOBI3,
			@SCSM_YOBI4,
			@SCSM_YOBI5,
			@SCSM_YOBI6,
			@SCSM_YOBI7,
			@SCSM_YOBI8,
			@SCSM_YOBI9,
			@SCSM_IMPORTYMD,
			@SCSM_IMPORTFILE,
			@SCSM_DELFG,
			@SCSM_INYMD,
			@SCSM_INTANTO,
			@SCSM_KOSINYMD,
			@SCSM_KOSINTANTO
		);

		IF @SCSM_DELFG <> 2
		BEGIN
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		DECLARE @now datetime = GETDATE();

		-- APP_CATSHN_MST

		SELECT *
		INTO #wt_APP_CATSHN_MST_SET_1_1
		FROM APP_CATSHN_MST_now
		WHERE SCSM_KCD = @SCSM_KCD
			AND SCSM_HTCD = @SCSM_HTCD
			AND SCSM_LCATCD = @SCSM_LCATCD
			AND SCSM_MCATCD = @SCSM_MCATCD
			AND SCSM_SCATCD = @SCSM_SCATCD
			AND SCSM_SCD = @SCSM_SCD
			AND SCSM_TEKIYOYMD > @SCSM_TEKIYOYMD
			AND SCSM_DELFG <> 1;

		UPDATE #wt_APP_CATSHN_MST_SET_1_1
		SET SCSM_DELFG = 1,
			SCSM_KOSINYMD = @now,
			SCSM_KOSINTANTO = 'sqlserv_proc_APP_CATSHN_MST_SET_1';

		INSERT INTO APP_CATSHN_MST_now
		SELECT *
		FROM #wt_APP_CATSHN_MST_SET_1_1;

		DROP TABLE #wt_APP_CATSHN_MST_SET_1_1;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_APP_CATSHN_MST_SET_1_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
