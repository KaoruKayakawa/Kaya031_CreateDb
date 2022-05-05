USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_MIXMATCH_M]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_MIXMATCH_M]
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
CREATE FUNCTION [dbo].[ft_MIXMATCH_M]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM MIXMATCH_M_now a
	INNER JOIN (
		SELECT MIM_HTCD, MIM_MMNO, MIM_SCD, MAX(MIM_TEKIYOYMD) AS MIM_TEKIYOYMD
		FROM MIXMATCH_M_now
		WHERE MIM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND MIM_DELFG <> 1
		GROUP BY MIM_HTCD, MIM_MMNO, MIM_SCD) b
	ON a.MIM_HTCD = b.MIM_HTCD
		AND a.MIM_MMNO = b.MIM_MMNO
		AND a.MIM_SCD = b.MIM_SCD
		AND a.MIM_TEKIYOYMD = b.MIM_TEKIYOYMD
	WHERE a.MIM_DELFG = 0
)
GO
