USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIXMATCHGRP_MST_SET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[MIXMATCHGRP_MST_SET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: MIXMATCHGRP_MST_SET_1
-- 機能			: テーブル MIXMATCHGRP_MST のレコード 1 件を登録する。
--					: SMGM_DELFG = 2 の場合は、適用日以降を無設定とする。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2022/03/09  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[MIXMATCHGRP_MST_SET_1]
	@SMGM_KCD int,
	@SMGM_HTCD int,
	@SMGM_MMNO int,
	@SMGM_TEKIYOYMD datetime,
	@SMGM_UPDATECNT int,
	@SMGM_HANEIYMD datetime,
	@SMGM_MMNOBIG bigint,
	@SMGM_MMNAME varchar(60),
	@SMGM_MMSTR datetime,
	@SMGM_MMEND datetime,
	@SMGM_SETKOSU1 int,
	@SMGM_SETKINGAKU1 int,
	@SMGM_SETKOSU2 int,
	@SMGM_SETKINGAKU2 int,
	@SMGM_YDELKBN int,
	@SMGM_MDELKBN int,
	@SMGM_YOBI1 int,
	@SMGM_YOBI2 int,
	@SMGM_YOBI3 int,
	@SMGM_YOBI4 varchar(100),
	@SMGM_YOBI5 varchar(100),
	@SMGM_YOBI6 varchar(100),
	@SMGM_YOBI7 datetime,
	@SMGM_YOBI8 datetime,
	@SMGM_YOBI9 datetime,
	@SMGM_IMPORTYMD datetime,
	@SMGM_IMPORTFILE varchar(100),
	@SMGM_DELFG tinyint,
	@SMGM_INYMD datetime,
	@SMGM_INTANTO varchar(100),
	@SMGM_KOSINYMD datetime,
	@SMGM_KOSINTANTO varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_MIXMATCHGRP_MST_SET_1_1;
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
		INSERT INTO MIXMATCHGRP_MST_now
		VALUES (
			@SMGM_KCD,
			@SMGM_HTCD,
			@SMGM_MMNO,
			@SMGM_TEKIYOYMD,
			@SMGM_UPDATECNT,
			@SMGM_HANEIYMD,
			@SMGM_MMNOBIG,
			@SMGM_MMNAME,
			@SMGM_MMSTR,
			@SMGM_MMEND,
			@SMGM_SETKOSU1,
			@SMGM_SETKINGAKU1,
			@SMGM_SETKOSU2,
			@SMGM_SETKINGAKU2,
			@SMGM_YDELKBN,
			@SMGM_MDELKBN,
			@SMGM_YOBI1,
			@SMGM_YOBI2,
			@SMGM_YOBI3,
			@SMGM_YOBI4,
			@SMGM_YOBI5,
			@SMGM_YOBI6,
			@SMGM_YOBI7,
			@SMGM_YOBI8,
			@SMGM_YOBI9,
			@SMGM_IMPORTYMD,
			@SMGM_IMPORTFILE,
			@SMGM_DELFG,
			@SMGM_INYMD,
			@SMGM_INTANTO,
			@SMGM_KOSINYMD,
			@SMGM_KOSINTANTO
		);

		IF @SMGM_DELFG = 0
		BEGIN
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		DECLARE @now datetime = GETDATE();

		---- MIXMATCH_MST（グループが削除されたので、定期ジョブで受注ＤＢへの再登録が試みられるよう、レコードを更新しておく。商品は受注ＤＢに登録されない。）
		SELECT *
		INTO #wt_MIXMATCHGRP_MST_SET_1_2
		FROM ft_MIXMATCH_MST(@SMGM_TEKIYOYMD) 
		WHERE SMIM_KCD = @SMGM_KCD
			AND SMIM_HTCD = @SMGM_HTCD
			AND SMIM_MMNO = @SMGM_MMNO;

		UPDATE #wt_MIXMATCHGRP_MST_SET_1_2
		SET SMIM_KOSINYMD = @now,
			SMIM_KOSINTANTO = 'sqlserv_proc_MIXMATCHGRP_MST_SET_1';

		INSERT INTO MIXMATCH_MST_now
		SELECT *
		FROM #wt_MIXMATCHGRP_MST_SET_1_2;

		DROP TABLE #wt_MIXMATCHGRP_MST_SET_1_2;

		IF @SMGM_DELFG = 1
		BEGIN
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		-- MIXMATCHGRP_MST

		SELECT *
		INTO #wt_MIXMATCHGRP_MST_SET_1_1
		FROM MIXMATCHGRP_MST_now
		WHERE SMGM_KCD = @SMGM_KCD
			AND SMGM_HTCD = @SMGM_HTCD
			AND SMGM_MMNO = @SMGM_MMNO
			AND SMGM_TEKIYOYMD > @SMGM_TEKIYOYMD
			AND SMGM_DELFG <> 1;

		UPDATE #wt_MIXMATCHGRP_MST_SET_1_1
		SET SMGM_DELFG = 1,
			SMGM_KOSINYMD = @now,
			SMGM_KOSINTANTO = 'sqlserv_proc_MIXMATCHGRP_MST_SET_1';

		INSERT INTO MIXMATCHGRP_MST_now
		SELECT *
		FROM #wt_MIXMATCHGRP_MST_SET_1_1;

		DROP TABLE #wt_MIXMATCHGRP_MST_SET_1_1;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_MIXMATCHGRP_MST_SET_1_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
