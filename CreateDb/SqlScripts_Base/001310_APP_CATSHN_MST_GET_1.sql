USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APP_CATSHN_MST_GET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[APP_CATSHN_MST_GET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: APP_CATSHN_MST_GET_1
-- 機能			: 一時テーブル [#wt_APP_CATSHN_MST_GET_1_1] の、以下項目に合致するレコードを、[vi_APP_CATSHN_MST] から取得する。
--					: CCS_KCD, CCS_TENCD, CCS_SCD, CCS_LCATCD, CCS_MCATCD, CCS_SCATCD
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[APP_CATSHN_MST_GET_1]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;

	BEGIN TRY
		WITH
			t2 AS (
				SELECT DISTINCT CCS_KCD, CCS_TENCD, CCS_SCD, CCS_LCATCD, CCS_MCATCD, CCS_SCATCD
				FROM #wt_APP_CATSHN_MST_GET_1_1
			)
		SELECT t1.*
		FROM vi_APP_CATSHN_MST t1
		INNER JOIN t2
		ON t1.SCSM_KCD = t2.CCS_KCD
			AND t1.SCSM_HTCD = t2.CCS_TENCD
			AND t1.SCSM_SCD = t2.CCS_SCD
			AND t1.SCSM_LCATCD = t2.CCS_LCATCD
			AND t1.SCSM_MCATCD = t2.CCS_MCATCD
			AND t1.SCSM_SCATCD = t2.CCS_SCATCD;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
