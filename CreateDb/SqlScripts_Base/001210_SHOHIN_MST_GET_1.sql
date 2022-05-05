USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SHOHIN_MST_GET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[SHOHIN_MST_GET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: SHOHIN_MST_GET_1
-- 機能			: 一時テーブル [#wt_SHOHIN_MST_GET_1_1] の、以下項目に合致するレコードを、[vi_SHOHIN_MST] から取得する。
--					: CSH_KAICD, CSH_TENCD, CSH_SCD
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[SHOHIN_MST_GET_1]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;

	BEGIN TRY
		WITH
			t2 AS (
				SELECT DISTINCT CSH_KAICD, CSH_TENCD, CSH_SCD
				FROM #wt_SHOHIN_MST_GET_1_1
			)
		SELECT t1.*
		FROM vi_SHOHIN_MST t1
		INNER JOIN t2
		ON t1.SSHM_KCD = t2.CSH_KAICD
			AND t1.SSHM_HTCD = t2.CSH_TENCD
			AND t1.SSHM_SCD = t2.CSH_SCD;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
