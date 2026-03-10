  <!-- Language chooser -->
  <xsl:template name="build-lang-chooser">
    <xsl:choose>
      <xsl:when test="count($langList) = 2">
        <xsl:variable name="otherLang" select="string($langList[not(. = $lang)][1])"/>
        <xsl:variable name="otherLangLabel" select="upper-case(string($otherLang))"/>
        <xsl:variable name="ariaLabel">
          <xsl:call-template name="get-text-value">
            <xsl:with-param name="element" select="$properties/lang-chooser/aria-label"/>
          </xsl:call-template>
        </xsl:variable>
        <a class="lang-chooser"
           aria-label="{$ariaLabel}" lang="{$otherLang}">
          <xsl:attribute name="href">
            <xsl:text>../</xsl:text>
            <xsl:value-of select="$otherLang"/>
            <xsl:text>/</xsl:text>
            <xsl:choose>
              <xsl:when test="$isLanding">index.html</xsl:when>
              <xsl:otherwise>{{currentPage}}</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="$otherLangLabel"/>
        </a>
      </xsl:when>
      <xsl:when test="count($langList) gt 2">
        <div id="languageSwitcher" class="language-switcher-dropdown">
          <button class="language-switcher-button">
            <xsl:value-of select="hcmc:getLanguageLabel($lang)"/>
            <span class="dropdown-arrow">▼</span>
          </button>
          <ul class="language-switcher-menu">
            <xsl:for-each select="$langList[not(. = $lang)]">
              <li>
                <a>
                  <xsl:attribute name="href">
                    <xsl:text>../</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>/</xsl:text>
                    <xsl:choose>
                      <xsl:when test="$isLanding">index.html</xsl:when>
                      <xsl:otherwise>{{currentPage}}</xsl:otherwise>
                    </xsl:choose>
                  </xsl:attribute>
                  <xsl:value-of select="hcmc:getLanguageLabel(.)"/>
                </a>
              </li>
            </xsl:for-each>
          </ul>
        </div>
      </xsl:when>
    </xsl:choose>
  </xsl:template>