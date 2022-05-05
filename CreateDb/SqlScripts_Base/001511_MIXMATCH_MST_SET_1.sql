USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIXMATCH_MST_SET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[MIXMATCH_MST_SET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: MIXMATCH_MST_SET_1
-- 機能			: テーブル MIXMATCH_MST のレコード 1 件を登録する。
--					: SMIM_DELFG = 2 の場合は、適用日以降を無設定とする。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2022/03/09  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[MIXMATCH_MST_SET_1]
	@SMIM_KCD int,
	@SMIM_HTCD int,
	@SMIM_MMNO int,
	@SMIM_SCD bigint,
	@SMIM_TEKIYOYMD datetime,
	@SMIM_UPDATECNT int,
	@SMIM_HANEIYMD datetime,
	@SMIM_MMNOBIG bigint,
	@SMIM_YDELKBN int,
	@SMIM_MDELKBN int,
	@SMIM_YOBI1 int,
	@SMIM_YOBI2 int,
	@SMIM_YOBI3 int,
	@SMIM_YOBI4 varchar(100),
	@SMIM_YOBI5 varchar(100),
	@SMIM_YOBI6 varchar(100),
	@SMIM_YOBI7 datetime,
	@SMIM_YOBI8 datetime,
	@SMIM_YOBI9 datetime,
	@SMIM_IMPORTYMD datetime,
	@SMIM_IMPORTFILE varchar(100),
	@SMIM_DELFG tinyint,
	@SMIM_INYMD datetime,
	@SMIM_INTANTO varchar(100),
	@SMIM_KOSINYMD datetime,
	@SMIM_KOSINTANTO varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_MIXMATCH_MST_SET_1_1;
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
		INSERT INTO MIXMATCH_MST_now
		VALUES (
			@SMIM_KCD,
			@SMIM_HTCD,
			@SMIM_MMNO,
			@SMIM_SCD,
			@SMIM_TEKIYOYMD,
			@SMIM_UPDATECNT,
			@SMIM_HANEIYMD,
			@SMIM_MMNOBIG,
			@SMIM_YDELKBN,
			@SMIM_MDELKBN,
			@SMIM_YOBI1,
			@SMIM_YOBI2,
			@SMIM_YOBI3,
			@SMIM_YOBI4,
			@SMIM_YOBI5,
			@SMIM_YOBI6,
			@SMIM_YOBI7,
			@SMIM_YOBI8,
			@SMIM_YOBI9,
			@SMIM_IMPORTYMD,
			@SMIM_IMPORTFILE,
			@SMIM_DELFG,
			@SMIM_INYMD,
			@SMIM_INTANTO,
			@SMIM_KOSINYMD,
			@SMIM_KOSINTANTO
		);

		IF @SMIM_DELFG = 0
		BEGIN
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		DECLARE @now datetime = GETDATE();

		---- MIXMATCHGRP_MST（商品が削除されたので、定期ジョブで受注ＤＢへの再登録が試みられるよう、レコードを更新しておく。商品数が 0 なら、グループは受注ＤＢに登録されない。）
		SELECT *
		INTO #wt_MIXMATCH_MST_SET_1_2
		FROM ft_MIXMATCHGRP_MST(@SMIM_TEKIYOYMD) 
		WHERE SMGM_KCD = @SMIM_KCD
			AND SMGM_HTCD = @SMIM_HTCD
			AND SMGM_MMNO = @SMIM_MMNO;

		UPDATE #wt_MIXMATCH_MST_SET_1_2
		SET SMGM_KOSINYMD = @now,
			SMGM_KOSINTANTO = 'sqlserv_proc_MIXMATCH_MST_SET_1';

		INSERT INTO MIXMATCHGRP_MST_now
		SELECT *
		FROM #wt_MIXMATCH_MST_SET_1_2;

		DROP TABLE #wt_MIXMATCH_MST_SET_1_2;

		IF @SMIM_DELFG = 1
		BEGIN
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		-- MIXMATCH_MST

		SELECT *
		INTO #wt_MIXMATCH_MST_SET_1_1
		FROM MIXMATCH_MST_now
		WHERE SMIM_KCD = @SMIM_KCD
			AND SMIM_HTCD = @SMIM_HTCD
			AND SMIM_MMNOBIG = @SMIM_MMNOBIG
			AND SMIM_SCD = @SMIM_SCD
			AND SMIM_TEKIYOYMD > @SMIM_TEKIYOYMD
			AND SMIM_DELFG <> 1;

		UPDATE #wt_MIXMATCH_MST_SET_1_1
		SET SMIM_DELFG = 1,
			SMIM_KOSINYMD = @now,
			SMIM_KOSINTANTO = 'sqlserv_proc_MIXMATCH_MST_SET_1';

		INSERT INTO MIXMATCH_MST_now
		SELECT *
		FROM #wt_MIXMATCH_MST_SET_1_1;

		DROP TABLE #wt_MIXMATCH_MST_SET_1_1;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_MIXMATCH_MST_SET_1_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
