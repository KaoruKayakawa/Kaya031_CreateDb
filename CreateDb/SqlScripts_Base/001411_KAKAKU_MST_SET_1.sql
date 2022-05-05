USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KAKAKU_MST_SET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[KAKAKU_MST_SET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: KAKAKU_MST_SET_1
-- 機能			: テーブル KAKAKU_MST のレコード 1 件を登録する。
--					: SKAK_DELFG = 2 の場合は、適用日以降を無設定とする。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2022/03/07  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[KAKAKU_MST_SET_1]
	@SKAK_KCD int,
	@SKAK_HTCD int,
	@SKAK_SCD bigint,
	@SKAK_TOKUSTR datetime,
	@SKAK_TOKUEND datetime,
	@SKAK_TEKIYOYMD datetime,
	@SKAK_UPDATECNT int,
	@SKAK_HANEIYMD datetime,
	@SKAK_KIKAKUCD bigint,
	@SKAK_KIKAKUKBN int,
	@SKAK_TOKUKBN int,
	@SKAK_TOKUGENKA float,
	@SKAK_TOKUTANKA int,
	@SKAK_TSURYOSEIGEN smallint,
	@SKAK_TOKUKEISAIJUN int,
	@SKAK_MAXBAIKA int,
	@SKAK_100BAIKA int,
	@SKAK_MINBAIKA int,
	@SKAK_SURYOSEIGEN smallint,
	@SKAK_SEIGYOKBN smallint,
	@SKAK_TEISHIKBN smallint,
	@SKAK_TOKUSJKBN int,
	@SKAK_TYUKNRFLG tinyint,
	@SKAK_MCHKKBN tinyint,
	@SKAK_YDELKBN int,
	@SKAK_MDELKBN int,
	@SKAK_YOBI1 int,
	@SKAK_YOBI2 int,
	@SKAK_YOBI3 int,
	@SKAK_YOBI4 varchar(100),
	@SKAK_YOBI5 varchar(100),
	@SKAK_YOBI6 varchar(100),
	@SKAK_YOBI7 datetime,
	@SKAK_YOBI8 datetime,
	@SKAK_YOBI9 datetime,
	@SKAK_IMPORTYMD datetime,
	@SKAK_IMPORTFILE varchar(100),
	@SKAK_KEISAI_OVERRIDE int,
	@SKAK_DELFG tinyint,
	@SKAK_INYMD datetime,
	@SKAK_INTANTO varchar(100),
	@SKAK_KOSINYMD datetime,
	@SKAK_KOSINTANTO varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_KAKAKU_MST_SET_1_1;
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
		INSERT INTO KAKAKU_MST_now
		VALUES (
			@SKAK_KCD,
			@SKAK_HTCD,
			@SKAK_SCD,
			@SKAK_TOKUSTR,
			@SKAK_TOKUEND,
			@SKAK_TEKIYOYMD,
			@SKAK_UPDATECNT,
			@SKAK_HANEIYMD,
			@SKAK_KIKAKUCD,
			@SKAK_KIKAKUKBN,
			@SKAK_TOKUKBN,
			@SKAK_TOKUGENKA,
			@SKAK_TOKUTANKA,
			@SKAK_TSURYOSEIGEN,
			@SKAK_TOKUKEISAIJUN,
			@SKAK_MAXBAIKA,
			@SKAK_100BAIKA,
			@SKAK_MINBAIKA,
			@SKAK_SURYOSEIGEN,
			@SKAK_SEIGYOKBN,
			@SKAK_TEISHIKBN,
			@SKAK_TOKUSJKBN,
			@SKAK_TYUKNRFLG,
			@SKAK_MCHKKBN,
			@SKAK_YDELKBN,
			@SKAK_MDELKBN,
			@SKAK_YOBI1,
			@SKAK_YOBI2,
			@SKAK_YOBI3,
			@SKAK_YOBI4,
			@SKAK_YOBI5,
			@SKAK_YOBI6,
			@SKAK_YOBI7,
			@SKAK_YOBI8,
			@SKAK_YOBI9,
			@SKAK_IMPORTYMD,
			@SKAK_IMPORTFILE,
			@SKAK_KEISAI_OVERRIDE,
			@SKAK_DELFG,
			@SKAK_INYMD,
			@SKAK_INTANTO,
			@SKAK_KOSINYMD,
			@SKAK_KOSINTANTO
		);

		IF @SKAK_DELFG <> 2
		BEGIN
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		DECLARE @now datetime = GETDATE();

		-- KAKAKU_MST

		SELECT *
		INTO #wt_KAKAKU_MST_SET_1_1
		FROM KAKAKU_MST_now
		WHERE SKAK_KCD = @SKAK_KCD
			AND SKAK_HTCD = @SKAK_HTCD
			AND SKAK_SCD = @SKAK_SCD
			AND SKAK_KIKAKUCD = @SKAK_KIKAKUCD
			AND SKAK_TEKIYOYMD > @SKAK_TEKIYOYMD
			AND SKAK_DELFG <> 1;

		UPDATE #wt_KAKAKU_MST_SET_1_1
		SET SKAK_DELFG = 1,
			SKAK_KOSINYMD = @now,
			SKAK_KOSINTANTO = 'sqlserv_proc_KAKAKU_MST_SET_1';

		INSERT INTO KAKAKU_MST_now
		SELECT *
		FROM #wt_KAKAKU_MST_SET_1_1;

		DROP TABLE #wt_KAKAKU_MST_SET_1_1;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_KAKAKU_MST_SET_1_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
