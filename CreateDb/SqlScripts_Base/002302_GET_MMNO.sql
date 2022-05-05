USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GET_MMNO]') AND type in (N'P'))
DROP PROCEDURE [dbo].[GET_MMNO]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: GET_MMNO
-- 機能			: ミックス番号を取得する。
--				　※ レコード更新も行う。
--				　※ ミックス番号の再利用が行われた場合、登録商品は削除される。
-- 引き数		: 
--		@csvMmno: CSVミックス番号
--		@mmEnd	: 終了日
--		@mmno	: ミックス番号（出力）
-- 戻り値		: 
-- 作成日		: 2021/06/04  作成者 : 茅川
-- 更新			: 2022/03/09  茅川
-- ====================================================
CREATE PROCEDURE [dbo].[GET_MMNO]
	@csvMmno bigint, @mmEnd datetime, @mmno int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_GET_MMNO_1;
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
		SET @mmno = NULL;

		SELECT @mmno = MMNO
		FROM MIXMATCH_MMNO
		WHERE CSVMMNO = @csvMmno;

		IF @mmno IS NOT NULL
		BEGIN
			UPDATE MIXMATCH_MMNO
			SET ENDYMD = @mmEnd
			WHERE MMNO = @mmno
				AND ENDYMD < @mmEnd;
				
			IF @TranCnt = 0
				COMMIT TRANSACTION;

			RETURN;
		END;

		DECLARE @csvMmno2 bigint;

		WITH
			t1 AS (
				SELECT TOP(1) *
				FROM MIXMATCH_MMNO
				WHERE ENDYMD IS NULL OR ENDYMD < DATEADD(day, -7, CAST(GETDATE() AS date))
				ORDER BY ENDYMD
			)
		SELECT @mmno = MMNO, @csvMmno2 = CSVMMNO
		FROM t1;

		IF @mmno IS NULL
		BEGIN
			SET @ErrMessage = N'割り当て可能な [ミックス番号] が、残っていません。';
			SET @ErrSeverity = 16;
			SET @ErrState = 10000;

			RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
		END;

		UPDATE MIXMATCH_MMNO
		SET CSVMMNO = @csvMmno,
			ENDYMD = @mmEnd
		WHERE MMNO = @mmno;

		SELECT *
		INTO #wt_GET_MMNO_1
		FROM MIXMATCH_MST_now
		WHERE SMIM_MMNOBIG = @csvMmno2
			AND SMIM_DELFG <> 1;

		UPDATE #wt_GET_MMNO_1
		SET SMIM_DELFG = 1,
			SMIM_KOSINYMD = GETDATE(),
			SMIM_KOSINTANTO = 'sqlserv_proc_GET_MMNO';

		INSERT INTO MIXMATCH_MST_now
		SELECT *
		FROM  #wt_GET_MMNO_1;

		DROP TABLE  #wt_GET_MMNO_1;

		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_GET_MMNO_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
