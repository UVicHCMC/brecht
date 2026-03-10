<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs">
  
  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>
  
  <!-- Parameters for language and template type -->
  <xsl:param name="lang" select="'en'"/>
  <xsl:param name="template" select="'content'"/>
  <xsl:param name="templateFile" select="if ($template = 'content') then '../boilerplate/contentPageTemplate.xml' else '../boilerplate/landingPageTemplate.xml'"/>
  
  <!-- Load properties file -->
  <xsl:variable name="properties" select="document('../properties.xml')/site"/>
  
  <!-- Load template file -->
  <xsl:variable name="templateDoc" select="document($templateFile)"/>
  
  <!-- Main template -->
  <xsl:template match="/">
    <xsl:apply-templates select="$templateDoc" mode="process-template"/>
  </xsl:template>
  
  <!-- Process template elements -->
  <xsl:template match="node() | @*" mode="process-template">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="process-template"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Process attributes with file paths and static values -->
  <xsl:template match="@*[contains(., '{?') and contains(., '}')]" mode="process-template" priority="1">
    <xsl:attribute name="{name()}">
      <xsl:call-template name="replace-static-placeholders">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
    </xsl:attribute>
  </xsl:template>
  
  <!-- Process processing instructions - only replace static/file-based ones -->
  <xsl:template match="processing-instruction()" mode="process-template" priority="1">
    <xsl:choose>
      <!-- Keep content placeholders for later processing -->
      <xsl:when test="name() = 'docContent'">
        <xsl:processing-instruction name="docContent"/>
      </xsl:when>
      
      <!-- Keep dynamic content placeholders for later processing -->
      <xsl:when test="name() = 'siteTitle' or name() = 'splashTitle' or name() = 'splashSubtitle' or name() = 'splashWhereWhen' or name() = 'navigationMenu' or name() = 'splashNavigationMenu' or name() = 'copyrightText' or name() = 'citationText' or name() = 'acknowledgementsText'">
        <xsl:copy/>
      </xsl:when>
      
      <!-- Replace static elements like logos -->
      <xsl:when test="name() = 'uvic-logo'">
        <img src="{$properties/files/uvic-logo}" width="100" height="26" alt="University of Victoria">
          <xsl:attribute name="alt">
            <xsl:call-template name="get-text-value">
              <xsl:with-param name="element" select="$properties/footer/uvic-logo-alt"/>
              <xsl:with-param name="fallback">University of Victoria</xsl:with-param>
            </xsl:call-template>
          </xsl:attribute>
        </img>
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Template to replace only static/file-based placeholders -->
  <xsl:template name="replace-static-placeholders">
    <xsl:param name="text"/>
    
    <xsl:variable name="step1" select="replace($text, '\{\?cssFile\}', $properties/files/css)"/>
    <xsl:variable name="step2" select="replace($step1, '\{\?faviconIco\}', $properties/files/favicon-ico)"/>
    <xsl:variable name="step3" select="replace($step2, '\{\?faviconSvg\}', $properties/files/favicon-svg)"/>
    <xsl:variable name="step4" select="replace($step3, '\{\?siteManifest\}', $properties/files/site-manifest)"/>
    <xsl:variable name="step5" select="replace($step4, '\{\?mobileLogo\}', $properties/files/mobile-logo)"/>
    <xsl:variable name="step6" select="replace($step5, '\{\?siteLogo\}', $properties/files/site-logo)"/>
    <xsl:variable name="step7" select="replace($step6, '\{\?mobileFooterLogo\}', $properties/files/mobile-footer-logo)"/>
    <xsl:variable name="step8" select="replace($step7, '\{\?footerLogo\}', $properties/files/footer-logo)"/>
    <xsl:variable name="step9" select="replace($step8, '\{\?uvicLogo\}', $properties/files/uvic-logo)"/>
    <xsl:variable name="step10" select="replace($step9, '\{\?uvicUrl\}', 'https://hcmc.uvic.ca')"/>
    
    <!-- Keep dynamic placeholders as-is for later processing -->
    <xsl:value-of select="$step10"/>
  </xsl:template>
  
  <!-- Template to get text value based on language with fallback -->
  <xsl:template name="get-text-value">
    <xsl:param name="element"/>
    <xsl:param name="fallback" select="''"/>
    
    <xsl:choose>
      <xsl:when test="$lang = 'fr' and $element/@fr">
        <xsl:value-of select="$element/@fr"/>
      </xsl:when>
      <xsl:when test="$element/@en">
        <xsl:value-of select="$element/@en"/>
      </xsl:when>
      <xsl:when test="$element != ''">
        <xsl:value-of select="$element"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$fallback"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>