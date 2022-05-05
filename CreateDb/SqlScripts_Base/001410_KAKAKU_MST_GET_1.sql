USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KAKAKU_MST_GET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[KAKAKU_MST_GET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: KAKAKU_MST_GET_1
-- 機能			: 一時テーブル [#wt_KAKAKU_MST_GET_1_1] の、以下項目に合致するレコードを、[vi_KAKAKU_MST] から取得する。
--					: CSS_KCD, CSS_TENCD, CSS_SCD, CSS_KIKAKUCD
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[KAKAKU_MST_GET_1]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;

	BEGIN TRY
		WITH
			t2 AS (
				SELECT DISTINCT CSS_KCD, CSS_TENCD, CSS_SCD, CSS_KIKAKUCD
				FROM #wt_KAKAKU_MST_GET_1_1
			)
		SELECT t1.*
		FROM vi_KAKAKU_MST t1
		INNER JOIN t2
		ON t1.SKAK_KCD = t2.CSS_KCD
			AND t1.SKAK_HTCD = t2.CSS_TENCD
			AND t1.SKAK_SCD = t2.CSS_SCD
			AND t1.SKAK_KIKAKUCD = t2.CSS_KIKAKUCD;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
