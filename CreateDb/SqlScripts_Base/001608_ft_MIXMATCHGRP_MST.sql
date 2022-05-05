USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_MIXMATCHGRP_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_MIXMATCHGRP_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		kayakawa
-- Create date:
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[ft_MIXMATCHGRP_MST]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM MIXMATCHGRP_MST_now a
	INNER JOIN (
		SELECT SMGM_KCD, SMGM_HTCD, SMGM_MMNO, MAX(SMGM_TEKIYOYMD) AS SMGM_TEKIYOYMD
		FROM MIXMATCHGRP_MST_now
		WHERE SMGM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND SMGM_DELFG <> 1
		GROUP BY SMGM_KCD, SMGM_HTCD, SMGM_MMNO) b
	ON a.SMGM_KCD = b.SMGM_KCD
		AND a.SMGM_HTCD = b.SMGM_HTCD
		AND a.SMGM_MMNO = b.SMGM_MMNO
		AND a.SMGM_TEKIYOYMD = b.SMGM_TEKIYOYMD
	WHERE a.SMGM_DELFG = 0
)
GO
