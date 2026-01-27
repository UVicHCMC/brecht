<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="#all"
                version="3.0">
  
  <xsl:output method="html" encoding="UTF-8" indent="yes" html-version="5.0"/>
  
  <xsl:variable name="props" select="document(resolve-uri('../properties.xml', base-uri(/)))"/>
  
  <xsl:variable name="languages" select="$props//languages/lang" as="element()*"/>
  <xsl:variable name="defaultLang" select="$languages[@default='true']/@code" as="xs:string"/>
  
  <!-- Root template -->
  <xsl:template match="/xhtml:html">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta http-equiv="refresh" content="0; url={$defaultLang}/"/>
        <title>Redirecting…</title>
        <script>
          <xsl:text>&#xa;  const userLang = (navigator.language || navigator.userLanguage).toLowerCase();&#xa;  </xsl:text>
          <xsl:for-each select="$languages">
            <xsl:choose>
              <xsl:when test="position() = 1">if</xsl:when>
              <xsl:otherwise>else if</xsl:otherwise>
            </xsl:choose>
            <xsl:text> (userLang.startsWith('</xsl:text>
            <xsl:value-of select="@code"/>
            <xsl:text>')) {&#xa;    window.location.replace('</xsl:text>
            <xsl:value-of select="@code"/>
            <xsl:text>/');&#xa;  }</xsl:text>
          </xsl:for-each>
          <xsl:text> else {&#xa;    window.location.replace('</xsl:text>
          <xsl:value-of select="$defaultLang"/>
          <xsl:text>/');&#xa;  }&#xa;</xsl:text>
        </script>
      </head>
      <body>
        <p>Redirecting… <a href="{$defaultLang}/">Click here if not redirected</a>.</p>
      </body>
    </html>
  </xsl:template>
  
</xsl:stylesheet>
