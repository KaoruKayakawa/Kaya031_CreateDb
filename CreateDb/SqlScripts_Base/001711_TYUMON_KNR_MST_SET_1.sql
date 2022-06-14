USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TYUMON_KNR_MST_SET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[TYUMON_KNR_MST_SET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: TYUMON_KNR_MST_SET_1
-- 機能			: テーブル TYUMON_KNR_MST のレコード 1 件を登録する。
--					: STKF_DELFG = 2 の場合は、適用日以降を無設定とする。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2022/03/09  作成者 : 茅川
-- 変更			: 2022/06/09  茅川
-- ====================================================
CREATE PROCEDURE [dbo].[TYUMON_KNR_MST_SET_1]
	@STKF_KCD int,
	@STKF_HTCD int,
	@STKF_KIKAKUCD bigint,
	@STKF_KIKAKUKBN int,
	@STKF_SCD bigint,
	@STKF_STR datetime,
	@STKF_END datetime,
	@STKF_TEKIYOYMD datetime,
	@STKF_UPDATECNT int,
	@STKF_HANEIYMD datetime,
	@STKF_SOURYO int,
	@STKF_NOWSURYO int,
	@STKF_SESSIONID varchar(30),
	@STKF_YDELKBN int,
	@STKF_MDELKBN int,
	@STKF_YOBI1 int,
	@STKF_YOBI2 int,
	@STKF_YOBI3 int,
	@STKF_YOBI4 varchar(100),
	@STKF_YOBI5 varchar(100),
	@STKF_YOBI6 varchar(100),
	@STKF_YOBI7 datetime,
	@STKF_YOBI8 datetime,
	@STKF_YOBI9 datetime,
	@STKF_IMPORTYMD datetime,
	@STKF_IMPORTFILE varchar(100),
	@STKF_DELFG tinyint,
	@STKF_INYMD datetime,
	@STKF_INTANTO varchar(100),
	@STKF_KOSINYMD datetime,
	@STKF_KOSINTANTO varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_TYUMON_KNR_MST_SET_1_1;
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
		INSERT INTO TYUMON_KNR_MST_now
		VALUES (
			@STKF_KCD,
			@STKF_HTCD,
			@STKF_KIKAKUCD,
			@STKF_KIKAKUKBN,
			@STKF_SCD,
			@STKF_STR,
			@STKF_END,
			@STKF_TEKIYOYMD,
			@STKF_UPDATECNT,
			@STKF_HANEIYMD,
			@STKF_SOURYO,
			@STKF_NOWSURYO,
			@STKF_SESSIONID,
			@STKF_YDELKBN,
			@STKF_MDELKBN,
			@STKF_YOBI1,
			@STKF_YOBI2,
			@STKF_YOBI3,
			@STKF_YOBI4,
			@STKF_YOBI5,
			@STKF_YOBI6,
			@STKF_YOBI7,
			@STKF_YOBI8,
			@STKF_YOBI9,
			@STKF_IMPORTYMD,
			@STKF_IMPORTFILE,
			@STKF_DELFG,
			@STKF_INYMD,
			@STKF_INTANTO,
			@STKF_KOSINYMD,
			@STKF_KOSINTANTO
		);

		IF @STKF_DELFG <> 2
		BEGIN
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		DECLARE @now datetime = GETDATE();

		-- TYUMON_KNR_MST

		SELECT *
		INTO #wt_TYUMON_KNR_MST_SET_1_1
		FROM TYUMON_KNR_MST_now
		WHERE STKF_KCD = @STKF_KCD
			AND STKF_HTCD = @STKF_HTCD
			AND STKF_SCD = @STKF_SCD
			AND STKF_KIKAKUCD = @STKF_KIKAKUCD
			AND STKF_TEKIYOYMD > @STKF_TEKIYOYMD
			AND STKF_DELFG <> 1;

		UPDATE #wt_TYUMON_KNR_MST_SET_1_1
		SET STKF_DELFG = 1,
			STKF_KOSINYMD = @now,
			STKF_KOSINTANTO = 'sqlserv_proc_TYUMON_KNR_MST_SET_1';

		INSERT INTO TYUMON_KNR_MST_now
		SELECT *
		FROM #wt_TYUMON_KNR_MST_SET_1_1;

		DROP TABLE #wt_TYUMON_KNR_MST_SET_1_1;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_TYUMON_KNR_MST_SET_1_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
