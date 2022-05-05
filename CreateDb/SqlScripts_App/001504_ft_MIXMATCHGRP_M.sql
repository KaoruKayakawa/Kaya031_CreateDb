USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_MIXMATCHGRP_M]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_MIXMATCHGRP_M]
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
CREATE FUNCTION [dbo].[ft_MIXMATCHGRP_M]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM MIXMATCHGRP_M_now a
	INNER JOIN (
		SELECT MGM_HTCD, MGM_MMNO, MAX(MGM_TEKIYOYMD) AS MGM_TEKIYOYMD
		FROM MIXMATCHGRP_M_now
		WHERE MGM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND MGM_DELFG <> 1
		GROUP BY MGM_HTCD, MGM_MMNO) b
	ON a.MGM_HTCD = b.MGM_HTCD
		AND a.MGM_MMNO = b.MGM_MMNO
		AND a.MGM_TEKIYOYMD = b.MGM_TEKIYOYMD
	WHERE a.MGM_DELFG = 0
)
GO
