USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TYUMON_KNR_MST_GET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[TYUMON_KNR_MST_GET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: TYUMON_KNR_MST_GET_1
-- 機能			: 一時テーブル [#wt_TYUMON_KNR_MST_GET_1_1] の、以下項目に合致するレコードを、[vi_TYUMON_KNR_MST] から取得する。
--					: CSO_KCD, CSO_TENCD, CSO_SCD, CSO_KIKAKUCD
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- 変更			: 2022/06/09  茅川
-- ====================================================
CREATE PROCEDURE [dbo].[TYUMON_KNR_MST_GET_1]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;

	BEGIN TRY
		WITH
			t2 AS (
				SELECT DISTINCT CSO_KCD, CSO_TENCD, CSO_SCD, CSO_KIKAKUCD
				FROM #wt_TYUMON_KNR_MST_GET_1_1
			)
		SELECT t1.*
		FROM vi_TYUMON_KNR_MST t1
		INNER JOIN t2
		ON t1.STKF_KCD = t2.CSO_KCD
			AND t1.STKF_HTCD = t2.CSO_TENCD
			AND t1.STKF_SCD = t2.CSO_SCD
			AND t1.STKF_KIKAKUCD = t2.CSO_KIKAKUCD;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
