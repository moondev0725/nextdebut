package com.java.game.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.time.LocalDateTime;
import java.time.LocalDate;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "TRAINEE")
public class Trainee {

	@Id
	@GeneratedValue(strategy = GenerationType.AUTO)
	@Column(name = "ID")
	private Long id;

	@Column(name = "NAME")
	private String name;

	@Enumerated(EnumType.STRING)
	@Column(name = "GENDER")
	private Gender gender;

	@Enumerated(EnumType.STRING)
	@Column(name = "GRADE")
	private Grade grade;

	@Column(name = "VOCAL")
	private int vocal;

	@Column(name = "DANCE")
	private int dance;

	@Column(name = "STAR")
	private int star;

	@Column(name = "MENTAL")
	private int mental;

	@Column(name = "TEAMWORK")
	private int teamwork;

	@Column(name = "IMAGE_PATH")
	private String imagePath;

	/* ── 추가 프로필 필드 ── */
	@Column(name = "AGE")
	private Integer age; // 나이

	@Column(name = "BIRTHDAY")
	private LocalDate birthday; // 생일

	@Column(name = "HEIGHT")
	private Integer height; // 키 (cm)

	@Column(name = "WEIGHT")
	private Integer weight; // 몸무게 (kg)

	@Column(name = "HOBBY")
	private String hobby; // 취미

	@Column(name = "MOTTO")
	private String motto; // 좌우명

	@Column(name = "INSTAGRAM")
	private String instagram; // 인스타그램 아이디

	/* ── 게임 대사 톤용 성격 코드 ── */
	@Column(name = "PERSONALITY_CODE", length = 32)
	private String personalityCode;

	@CreationTimestamp
	@Column(name = "CREATED_AT", updatable = false)
	private LocalDateTime createdAt;

	protected Trainee() {
	}

	/* 기존 생성자 유지 */
	public Trainee(String name, Gender gender, Grade grade, int vocal, int dance, int star, int mental, int teamwork,
			String imagePath) {
		this.name = name;
		this.gender = gender;
		this.grade = grade;
		this.vocal = vocal;
		this.dance = dance;
		this.star = star;
		this.mental = mental;
		this.teamwork = teamwork;
		this.imagePath = imagePath;
	}

	/* 기존 getter */
	public Long getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public Gender getGender() {
		return gender;
	}

	public Grade getGrade() {
		return grade;
	}

	public int getVocal() {
		return vocal;
	}

	public int getDance() {
		return dance;
	}

	public int getStar() {
		return star;
	}

	public int getMental() {
		return mental;
	}

	public int getTeamwork() {
		return teamwork;
	}

	public String getImagePath() {
		return imagePath;
	}

	/* 추가 프로필 getter */
	public Integer getAge() {
		return age;
	}

	public Integer getHeight() {
		return height;
	}

	public LocalDate getBirthday() {
		return birthday;
	}

	public Integer getWeight() {
		return weight;
	}

	public String getHobby() {
		return hobby;
	}

	public String getMotto() {
		return motto;
	}

	public String getInstagram() {
		return instagram;
	}

	public String getPersonalityCode() {
		return personalityCode;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	@Transient
	public int getVocalPercent() {
		return this.vocal;
	}

	@Transient
	public int getDancePercent() {
		return this.dance;
	}

	@Transient
	public int getStarPercent() {
		return this.star;
	}

	@Transient
	public int getMentalPercent() {
		return this.mental;
	}

	@Transient
	public int getTeamworkPercent() {
		return this.teamwork;
	}

	/**
	 * 다섯 능력치의 0~100 표시값 평균. 내부 스탯 0~20(표시 5배)이므로 (v+d+s+m+t)과 같다.
	 */
	@Transient
	public int getAverageAbilityScore() {
		return this.vocal + this.dance + this.star + this.mental + this.teamwork;
	}

	/* 기본 정보 setter (어드민 수정용) */
	public void setName(String name) {
		this.name = name;
	}

	public void setGrade(Grade grade) {
		this.grade = grade;
	}

	public void setGender(Gender gender) {
		this.gender = gender;
	}

	public void setVocal(int vocal) {
		this.vocal = vocal;
	}

	public void setDance(int dance) {
		this.dance = dance;
	}

	public void setStar(int star) {
		this.star = star;
	}

	public void setMental(int mental) {
		this.mental = mental;
	}

	public void setTeamwork(int teamwork) {
		this.teamwork = teamwork;
	}

	/* 추가 프로필 setter */
	public void setAge(Integer age) {
		this.age = age;
	}

	public void setBirthday(LocalDate birthday) {
		this.birthday = birthday;
	}

	public void setHeight(Integer height) {
		this.height = height;
	}

	public void setWeight(Integer weight) {
		this.weight = weight;
	}

	public void setHobby(String hobby) {
		this.hobby = hobby;
	}

	public void setMotto(String motto) {
		this.motto = motto;
	}

	public void setInstagram(String instagram) {
		this.instagram = instagram;
	}

	public void setPersonalityCode(String personalityCode) {
		this.personalityCode = personalityCode;
	}

	public void setImagePath(String imagePath) {
		this.imagePath = imagePath;
	}

	/* ── 스탯 변경 (1~100 범위 클램프) ── */
	public void applyVocal(int delta) {
		this.vocal = clamp(this.vocal + delta);
	}

	public void applyDance(int delta) {
		this.dance = clamp(this.dance + delta);
	}

	public void applyStar(int delta) {
		this.star = clamp(this.star + delta);
	}

	public void applyMental(int delta) {
		this.mental = clamp(this.mental + delta);
	}

	public void applyTeamwork(int delta) {
		this.teamwork = clamp(this.teamwork + delta);
	}

	private static int clamp(int v) {
		// 6주 플랜: 초기엔 0부터 시작, 최대 20까지
		return Math.max(0, Math.min(100, v));
	}
}
