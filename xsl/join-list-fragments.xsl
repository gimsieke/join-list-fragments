<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
  xmlns:my="http://localhost/" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  exclude-result-prefixes="my xs">
  
  <xsl:mode on-no-match="shallow-copy"/>

  <xsl:include href="debug.xsl"/>
  
  <xsl:template match="*[ol[@data-meta = 'listlevel=start']]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:for-each-group select="my:atomic-items(.)" 
        group-starting-with="*[parent::li[not(@data-meta='listitem=empty')]
                                  /parent::ol/@data-meta = ('listlevel=start', 'listlevel=end')
                               and . is (parent::li/parent::ol/li/*)[1]]">
        <xsl:for-each-group select="current-group()" group-adjacent="(my:list-level(.), -1)[1] = 0">
          <!-- Exclude the uninteresting paras before, in between, and after lists.
          For interesting elements, my:list-level() is greater than 1 or empty (for the collect
          elements, but also for continuing list item content) -->
          <xsl:choose>
            <xsl:when test="current-grouping-key()">
              <xsl:copy-of select="current-group()"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="collect"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="my:atomic-items" as="node()*">
    <xsl:param name="context" as="element()"/>
    <xsl:sequence select="  innermost($context/descendant::li/*)
                          | outermost($context/descendant::*[empty(ancestor-or-self::ol)])"/>
  </xsl:function>
  
  <xsl:function name="my:list-level" as="xs:integer?">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt[@data-meta='collect' 
                           or 
                           parent::li/@data-meta = 'listitem=continue'
                           or
                           (exists(parent::li) and not(. is parent::li/*[1]))]"/>
      <xsl:otherwise>
        <xsl:sequence select="count($elt[. is parent::li/*[1]]/ancestor::li)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template name="collect">
    <xsl:param name="nodes" as="node()*" select="current-group()"/>
    <xsl:param name="depth" as="xs:integer" select="1"/>
    <xsl:copy select="../..">
      <!-- ol -->
      <xsl:copy-of select="@*"/>
      <xsl:for-each-group select="current-group()" group-starting-with="*[my:list-level(.) = $depth]">
        <xsl:copy select="..">
          <!-- li -->
          <xsl:copy-of select="@*"/>
          <xsl:choose>
            <xsl:when test="exists(current-group()[my:list-level(.) gt $depth])">
              <xsl:for-each-group select="current-group()" group-adjacent="not(my:list-level(.) = $depth)">
                <xsl:choose>
                  <xsl:when test="current-grouping-key()">
                    <xsl:for-each-group select="current-group()" 
                      group-starting-with="*[parent::li/parent::ol[not(@data-meta)]
                                             and . is parent::li/*[1]]">
                      <!-- we might need to consider @start-level (the number of total ancestor ol elements minus
                        the number of data-meta-less ancestor ol elements) that is calculated in debug.xsl -->  
                      <xsl:call-template name="collect">
                        <xsl:with-param name="depth" select="$depth + 1"/>
                      </xsl:call-template>  
                    </xsl:for-each-group>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="current-group()"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="current-group()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:copy>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>