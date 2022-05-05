USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SID_SCD_PAIR_GET_2]') AND type in (N'P'))
DROP PROCEDURE [dbo].[SID_SCD_PAIR_GET_2]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: SID_SCD_PAIR_GET_2
-- 機能			: 一時テーブル [#wt_SID_SCD_PAIR_GET_2_1] に設定された SID の変換レコードを取得する。
--					: 変換レコードが存在しない場合は、NULL が取得される。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[SID_SCD_PAIR_GET_2]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;

	BEGIN TRY
		WITH
			t1 AS (
				SELECT DISTINCT SSP_SID
				FROM #wt_SID_SCD_PAIR_GET_2_1
			)
		SELECT
			t1.SSP_SID,
			t2.SSP_SCD,
			t2.SSP_INYMD
		FROM t1
		LEFT OUTER JOIN SID_SCD_PAIR t2
		ON t1.SSP_SID = t2.SSP_SID;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
