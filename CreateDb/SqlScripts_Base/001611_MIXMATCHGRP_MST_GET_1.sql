USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIXMATCHGRP_MST_GET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[MIXMATCHGRP_MST_GET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: MIXMATCHGRP_MST_GET_1
-- 機能			: 一時テーブル [#wt_MIXMATCHGRP_MST_GET_1_1] の、以下項目に合致するレコードを、[vi_MIXMATCHGRP_MST] から取得する。
--					: CMG_KCD, CMG_TENCD, CMG_MMNO
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[MIXMATCHGRP_MST_GET_1]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;

	BEGIN TRY
		WITH
			t2 AS (
				SELECT DISTINCT CMG_KCD, CMG_TENCD, CMG_MMNO
				FROM #wt_MIXMATCHGRP_MST_GET_1_1
			)
		SELECT t1.*
		FROM vi_MIXMATCHGRP_MST t1
		INNER JOIN t2
		ON t1.SMGM_KCD = t2.CMG_KCD
			AND t1.SMGM_HTCD = t2.CMG_TENCD
			AND t1.SMGM_MMNOBIG = t2.CMG_MMNO;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
