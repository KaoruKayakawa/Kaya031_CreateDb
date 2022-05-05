USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_MIXMATCH_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_MIXMATCH_MST]
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
CREATE FUNCTION [dbo].[ft_MIXMATCH_MST]
(	
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM MIXMATCH_MST_now a
	INNER JOIN (
		SELECT SMIM_KCD, SMIM_HTCD, SMIM_MMNO, SMIM_SCD, MAX(SMIM_TEKIYOYMD) AS SMIM_TEKIYOYMD
		FROM MIXMATCH_MST_now
		WHERE SMIM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND SMIM_DELFG <> 1
		GROUP BY SMIM_KCD, SMIM_HTCD, SMIM_MMNO, SMIM_SCD) b
	ON a.SMIM_KCD = b.SMIM_KCD
		AND a.SMIM_HTCD = b.SMIM_HTCD
		AND a.SMIM_MMNO = b.SMIM_MMNO
		AND a.SMIM_SCD = b.SMIM_SCD
		AND a.SMIM_TEKIYOYMD = b.SMIM_TEKIYOYMD
	WHERE a.SMIM_DELFG = 0
)
GO