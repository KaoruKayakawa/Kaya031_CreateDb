USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_APP_CATSHN_M]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_APP_CATSHN_M]
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
CREATE FUNCTION [dbo].[ft_APP_CATSHN_M]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM APP_CATSHN_M_now a
	INNER JOIN (
		SELECT ACSM_HTCD, ACSM_LCATCD, ACSM_MCATCD, ACSM_SCATCD, ACSM_SCD, MAX(ACSM_TEKIYOYMD) AS ACSM_TEKIYOYMD
		FROM APP_CATSHN_M_now
		WHERE ACSM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND ACSM_DELFG <> 1
		GROUP BY ACSM_HTCD, ACSM_LCATCD, ACSM_MCATCD, ACSM_SCATCD, ACSM_SCD) b
	ON a.ACSM_HTCD = b.ACSM_HTCD
		AND a.ACSM_LCATCD = b.ACSM_LCATCD
		AND a.ACSM_MCATCD = b.ACSM_MCATCD
		AND a.ACSM_SCATCD = b.ACSM_SCATCD
		AND a.ACSM_SCD = b.ACSM_SCD
		AND a.ACSM_TEKIYOYMD = b.ACSM_TEKIYOYMD
	WHERE a.ACSM_DELFG = 0
)
GO
