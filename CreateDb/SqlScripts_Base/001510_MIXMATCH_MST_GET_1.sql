USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIXMATCH_MST_GET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[MIXMATCH_MST_GET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: MIXMATCH_MST_GET_1
-- 機能			: 一時テーブル [#wt_MIXMATCH_MST_GET_1_1] の、以下項目に合致するレコードを、[vi_MIXMATCH_MST] から取得する。
--					: CMS_KCD, CMS_TENCD, CMS_MMNO, CMS_SCD
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[MIXMATCH_MST_GET_1]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;

	BEGIN TRY
		WITH
			t2 AS (
				SELECT DISTINCT CMS_KCD, CMS_TENCD, CMS_MMNO, CMS_SCD
				FROM #wt_MIXMATCH_MST_GET_1_1
			)
		SELECT t1.*
		FROM vi_MIXMATCH_MST t1
		INNER JOIN t2
		ON t1.SMIM_KCD = t2.CMS_KCD
			AND t1.SMIM_HTCD = t2.CMS_TENCD
			AND t1.SMIM_MMNOBIG = t2.CMS_MMNO
			AND t1.SMIM_SCD = t2.CMS_SCD;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
